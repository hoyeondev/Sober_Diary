import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Query private var allRecords: [DrinkRecord]

    @State private var didDrink: Bool = false
    @State private var drinkLevel: Double = 0.5
    @State private var selectedTypes: Set<String> = []
    @State private var customType: String = ""
    @State private var memo: String = ""
    @State private var showDeleteConfirm: Bool = false
    @State private var isLoaded: Bool = false
    @State private var memoFocusCount: Int = 0

    private var existingRecord: DrinkRecord? {
        let day = Calendar.current.startOfDay(for: date)
        return allRecords.first { Calendar.current.startOfDay(for: $0.date) == day }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        dateHeader
                        drinkToggleSection
                        if didDrink {
                            drinkAmountSection
                            drinkTypeSection
                            customTypeField
                        }
                        memoSection
                            .id("memo")
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: memoFocusCount) { _, _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut) {
                            proxy.scrollTo("memo", anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color("appBackground"))
            .safeAreaInset(edge: .bottom) {
                saveButton
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if existingRecord != nil {
                        Menu {
                            Button(role: .destructive) {
                                showDeleteConfirm = true
                            } label: {
                                Label("기록 삭제", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }

            }
            .onAppear(perform: loadIfNeeded)
        .onChange(of: allRecords) { _, _ in loadIfNeeded() }
            .confirmationDialog("이 날의 기록을 삭제할까요?",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("삭제", role: .destructive, action: deleteRecord)
                Button("취소", role: .cancel) {}
            }
            .tint(didDrink ? settings.drinkColor : settings.soberColor)
        }
    }

    private var dateHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(formattedDate)
                .font(.system(size: 22, weight: .bold))
            Text("이날의 기록을 남겨보세요.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }

    private var drinkToggleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $didDrink.animation(.easeInOut)) {
                HStack {
                    Image(systemName: didDrink ? "wineglass.fill" : "leaf.fill")
                        .foregroundStyle(didDrink ? settings.drinkColor : settings.soberColor)
                    Text(didDrink ? "오늘 마셨어요" : "오늘 마시지 않았어요")
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .tint(settings.drinkColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    private var drinkAmountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("음주량")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("\(Int(drinkLevel * 100))%")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(settings.drinkColor)
            }
            Slider(value: $drinkLevel, in: 0...1, step: 0.1)
                .tint(settings.drinkColor)
            HStack {
                Text("조금")
                Spacer()
                Text("적당히")
                Spacer()
                Text("많이")
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var drinkTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("술 종류")
                .font(.system(size: 15, weight: .semibold))
            FlowLayout(spacing: 8) {
                ForEach(PresetDrinkType.all, id: \.self) { type in
                    DrinkTypeChip(
                        label: type,
                        isSelected: selectedTypes.contains(type)
                    ) {
                        toggle(type: type)
                    }
                }
            }
        }
    }

    private var customTypeField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("기타 (직접 입력)")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            HStack {
                TextField("예: 하이볼", text: $customType)
                    .textFieldStyle(.roundedBorder)
                Button {
                    addCustomType()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(customType.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : settings.drinkColor)
                }
                .disabled(customType.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if !customAddedTypes.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(customAddedTypes, id: \.self) { type in
                        DrinkTypeChip(label: type, isSelected: true) {
                            selectedTypes.remove(type)
                        }
                    }
                }
            }
        }
    }

    private var customAddedTypes: [String] {
        selectedTypes.filter { !PresetDrinkType.all.contains($0) }.sorted()
    }

    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("메모")
                .font(.system(size: 15, weight: .semibold))
            MemoTextEditor(text: $memo, tintColor: didDrink ? settings.drinkColor : settings.soberColor, onFocus: { memoFocusCount += 1 })
                .frame(minHeight: 120)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Text("저장")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(didDrink ? settings.drinkColor : settings.soberColor)
        .foregroundStyle(.white)
    }

    private func toggle(type: String) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }

    private func addCustomType() {
        let trimmed = customType.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        selectedTypes.insert(trimmed)
        customType = ""
    }

    private func loadIfNeeded() {
        guard !isLoaded, let record = existingRecord else { return }
        didDrink = record.didDrink
        drinkLevel = record.drinkLevel
        selectedTypes = Set(record.drinkTypes)
        memo = record.memo
        isLoaded = true
    }

    private func save() {
        let day = Calendar.current.startOfDay(for: date)
        let typesToSave = didDrink ? Array(selectedTypes).sorted() : []

        if let record = existingRecord {
            record.didDrink = didDrink
            record.drinkLevel = drinkLevel
            record.drinkTypes = typesToSave
            record.memo = memo
        } else {
            let new = DrinkRecord(date: day,
                                  didDrink: didDrink,
                                  drinkTypes: typesToSave,
                                  drinkLevel: drinkLevel,
                                  memo: memo)
            modelContext.insert(new)
        }
        try? modelContext.save()
        dismiss()
    }

    private func deleteRecord() {
        guard let record = existingRecord else { return }
        modelContext.delete(record)
        try? modelContext.save()
        dismiss()
    }
}

private struct MemoTextEditor: UIViewRepresentable {
    @Binding var text: String
    var tintColor: Color = .accentColor
    var onFocus: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.returnKeyType = .done
        view.font = .systemFont(ofSize: 16)
        view.backgroundColor = .clear
        view.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text { uiView.text = text }
        uiView.tintColor = UIColor(tintColor)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MemoTextEditor
        init(_ parent: MemoTextEditor) { self.parent = parent }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.onFocus?()
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                textView.resignFirstResponder()
                return false
            }
            return true
        }
    }
}

#Preview {
    DayDetailView(date: Date())
        .modelContainer(for: DrinkRecord.self, inMemory: true)
}
