require "spec_helper"
require "krudmin_ai/data_operations/operation_runner"

RSpec.describe KrudminAI::DataOperations::OperationRunner do
  Operation = Struct.new(:status, :progress, :result, :error, keyword_init: true)

  class Store
    def start(operation) = operation.status = "running"
    def progress(operation, value) = operation.progress = value
    def complete(operation, result:) = operation.tap { |value| value.status = "completed"; value.result = result }
    def fail(operation, error:) = operation.tap { |value| value.status = "failed"; value.error = error }
  end

  it "reports worker progress and persists completion" do
    worker = ->(_operation, &progress) { progress.call(50); { "rows" => 2 } }
    operation = Operation.new(status: "queued", progress: 0)

    result = described_class.new(store: Store.new, worker:).call(operation)

    expect(result).to have_attributes(status: "completed", progress: 50, result: { "rows" => 2 })
  end

  it "does not run a cancelled operation" do
    worker = ->(_operation, &_progress) { raise "must not execute" }
    operation = Operation.new(status: "cancelled", progress: 0)

    expect(described_class.new(store: Store.new, worker:).call(operation)).to equal(operation)
  end
end
