module KrudminAI
  module DataOperations
    ExportProfile = Data.define(:name, :fields, :masks)
    ImportProfile = Data.define(:name, :mapping, :required_fields)
  end
end