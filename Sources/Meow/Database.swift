import MongoCore
import MongoClient
import MongoKitten
import Dispatch
import NIO

public class MeowDatabase {
    public let raw: MongoDatabase
    
    public init(_ database: MongoDatabase) {
        self.raw = database
    }
    
    public func collection<M: BaseModel>(for model: M.Type) -> MeowCollection<M> {
        return MeowCollection<M>(database: self, named: M.collectionName)
    }
    
    public subscript<M: BaseModel>(type: M.Type) -> MeowCollection<M> {
        return collection(for: type)
    }
    
    public func withTransaction<T>(
        with options: MongoSessionOptions = .init(),
        transactionOptions: MongoTransactionOptions? = nil,
        perform: (MeowTransactionDatabase) async throws -> T
    ) async throws -> T {
        let transaction = try await raw.startTransaction(autoCommitChanges: false, with: options, transactionOptions: transactionOptions)
        let meowDatabase = MeowTransactionDatabase(transaction)
        
        do {
            let result = try await perform(meowDatabase)
            try await transaction.commit()
            return result
        } catch {
            try await transaction.abort()
            throw error
        }
    }
}

public final class MeowTransactionDatabase: MeowDatabase {
    private let transaction: MongoTransactionDatabase
    
    fileprivate init(_ transaction: MongoTransactionDatabase) {
        self.transaction = transaction
        
        super.init(transaction)
    }
    
    public func commit() async throws {
        try await transaction.commit()
    }
}
