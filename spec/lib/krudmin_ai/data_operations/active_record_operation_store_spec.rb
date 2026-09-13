require "spec_helper"
require "krudmin_ai/data_operations/active_record_operation_store"

RSpec.describe KrudminAI::DataOperations::ActiveRecordOperationStore do
  OperationStoreRecord = Struct.new(:tenant, :idempotency_key, :kind, :status, :payload, :progress, :result, :error, keyword_init: true) do
    def update!(attributes)
      attributes.each { |key, value| public_send("#{key}=", value) }
    end
  end

  let(:model) do
    Class.new do
      class << self
        attr_accessor :records

        def create_or_find_by!(attributes)
          records.find { |record| attributes.all? { |key, value| record.public_send(key) == value } } || OperationStoreRecord.new(**attributes).tap { |record| yield record; records << record }
        end

        def find_by(attributes)
          records.find { |record| attributes.all? { |key, value| record.public_send(key) == value } }
        end
      end
    end.tap { |klass| klass.records = [] }
  end

  it "claims each tenant-bound idempotency key once and retains its lifecycle" do
    store = described_class.new(model:)
    operation = store.claim(tenant: :north, idempotency_key: "import-42", kind: :import, payload: { "rows" => 2 })

    expect(store.claim(tenant: :north, idempotency_key: "import-42", kind: :import)).to equal(operation)
    expect(store.find(tenant: :south, idempotency_key: "import-42", kind: :import)).to be_nil
    expect(store.start(operation).status).to eq("running")
    expect(store.progress(operation, 50).progress).to eq(50)
    expect(store.complete(operation, result: { "rows" => 2 }).status).to eq("completed")
    expect(operation.result).to eq("rows" => 2)
  end

  it "cancels active work and allows only failed work to retry" do
    store = described_class.new(model:)
    operation = store.claim(tenant: :north, idempotency_key: "import-43", kind: :import)

    expect(store.cancel(operation).status).to eq("cancelled")
    expect(store.retry(operation).status).to eq("cancelled")

    failed = store.claim(tenant: :north, idempotency_key: "import-44", kind: :import)
    store.fail(failed, error: "temporary provider failure")
    expect(store.retry(failed).status).to eq("retrying")
    expect(failed.error).to be_nil
  end
end
