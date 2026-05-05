import SwiftUI
import SwiftData

struct DayDetailView: View {
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allRecords: [DrinkRecord]

    @State private var didDrink: Bool = false
    @State private var selectedTypes: Set<String> = []
    @State private var customType: String = ""
    @State private var memo: String = ""
    @State private var showDeleteConfirm: Bool = false
    @State private var isLoaded: Bool = false
    @FocusState private var memoFocused: Bool

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
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    dateHeader
                    drinkToggleSection
                    if didDrink {
                        drinkTypeSection
                        customTypeField
                    }
                    memoSection
                }
                .padding(16)
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
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("완료") { memoFocused = false }
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
                        .foregroundStyle(didDrink ? Color("drinkPink") : Color("soberBlue"))
                    Text(didDrink ? "오늘 마셨어요" : "오늘 마시지 않았어요")
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .tint(Color("drinkPink"))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
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
                        .foregroundStyle(customType.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : Color("drinkPink"))
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
            TextEditor(text: $memo)
                .focused($memoFocused)
                .frame(minHeight: 120)
                .padding(8)
                .scrollContentBackground(.hidden)
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
        .tint(didDrink ? Color("drinkPink") : Color("soberBlue"))
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
        selectedTypes = Set(record.drinkTypes)
        memo = record.memo
        isLoaded = true
    }

    private func save() {
        let day = Calendar.current.startOfDay(for: date)
        let typesToSave = didDrink ? Array(selectedTypes).sorted() : []

        if let record = existingRecord {
            record.didDrink = didDrink
            record.drinkTypes = typesToSave
            record.memo = memo
        } else {
            let new = DrinkRecord(date: day,
                                  didDrink: didDrink,
                                  drinkTypes: typesToSave,
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

#Preview {
    DayDetailView(date: Date())
        .modelContainer(for: DrinkRecord.self, inMemory: true)
}
