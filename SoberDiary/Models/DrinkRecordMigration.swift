import SwiftData
import Foundation

// MARK: - Schema V1 (최초 출시 버전 - drinkAmount 없음)
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [DrinkRecord.self] }

    @Model
    final class DrinkRecord {
        var date: Date
        var didDrink: Bool
        var drinkTypes: [String]
        var memo: String
        var createdAt: Date

        init(date: Date, didDrink: Bool = false, drinkTypes: [String] = [], memo: String = "") {
            self.date = Calendar.current.startOfDay(for: date)
            self.didDrink = didDrink
            self.drinkTypes = drinkTypes
            self.memo = memo
            self.createdAt = Date()
        }
    }
}

// MARK: - Schema V2 (drinkAmount: String 추가 버전)
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [DrinkRecord.self] }

    @Model
    final class DrinkRecord {
        var date: Date
        var didDrink: Bool
        var drinkTypes: [String]
        var drinkAmount: String
        var memo: String
        var createdAt: Date

        init(date: Date, didDrink: Bool = false, drinkTypes: [String] = [], drinkAmount: String = "", memo: String = "") {
            self.date = Calendar.current.startOfDay(for: date)
            self.didDrink = didDrink
            self.drinkTypes = drinkTypes
            self.drinkAmount = drinkAmount
            self.memo = memo
            self.createdAt = Date()
        }
    }
}

// MARK: - Schema V3 (현재 버전 - drinkLevel: Double)
enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] { [DrinkRecord.self] }

    @Model
    final class DrinkRecord {
        var date: Date
        var didDrink: Bool
        var drinkTypes: [String]
        var drinkLevel: Double
        var memo: String
        var createdAt: Date

        init(date: Date, didDrink: Bool = false, drinkTypes: [String] = [], drinkLevel: Double = 0.5, memo: String = "") {
            self.date = Calendar.current.startOfDay(for: date)
            self.didDrink = didDrink
            self.drinkTypes = drinkTypes
            self.drinkLevel = drinkLevel
            self.memo = memo
            self.createdAt = Date()
        }
    }
}

// willMigrate에서 didMigrate로 변환 값 전달용 임시 저장소
private nonisolated(unsafe) var migrationLevelCache: [Date: Double] = [:]

// MARK: - Migration Plan
enum DrinkRecordMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]
    }

    // V1 → V2: drinkAmount String 필드 추가 (기본값 "" 적용, 경량 마이그레이션)
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )

    // V2 → V3: drinkAmount String → drinkLevel Double 변환
    static let migrateV2toV3 = MigrationStage.custom(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self,
        willMigrate: { context in
            let records = try context.fetch(FetchDescriptor<SchemaV2.DrinkRecord>())
            migrationLevelCache = Dictionary(uniqueKeysWithValues: records.map { record in
                let level: Double
                switch record.drinkAmount {
                case "조금":   level = 0.3
                case "적당히": level = 0.6
                case "많이":   level = 1.0
                default:       level = 0.5
                }
                return (record.date, level)
            })
        },
        didMigrate: { context in
            let records = try context.fetch(FetchDescriptor<SchemaV3.DrinkRecord>())
            for record in records {
                if let level = migrationLevelCache[record.date] {
                    record.drinkLevel = level
                }
            }
            try context.save()
            migrationLevelCache.removeAll()
        }
    )
}
