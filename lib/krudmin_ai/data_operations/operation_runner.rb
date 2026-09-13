module KrudminAI
  module DataOperations
    class OperationRunner
      def initialize(store:, worker:)
        @store = store
        @worker = worker
      end

      def call(operation)
        return operation if operation.status == "cancelled"

        store.start(operation)
        result = worker.call(operation) do |progress|
          store.progress(operation, progress)
          throw :cancelled if operation.status == "cancelled"
        end
        store.complete(operation, result: result)
      rescue UncaughtThrowError => error
        return operation if error.tag == :cancelled

        store.fail(operation, error: "Operation failed")
      rescue StandardError
        store.fail(operation, error: "Operation failed")
      end

      private

      attr_reader :store, :worker
    end
  end
end
