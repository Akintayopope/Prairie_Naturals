Rails.application.config.to_prepare do
  ActiveSupport.on_load(:active_storage_attachment) do
    ActiveStorage::Attachment.class_eval do
      def self.ransackable_attributes(auth_object = nil)
        %w[blob_id created_at id id_value name record_id record_type]
      end
    end
  end

  ActiveSupport.on_load(:active_storage_blob) do
    ActiveStorage::Blob.class_eval do
      def self.ransackable_attributes(auth_object = nil)
        %w[
          checksum content_type created_at filename id id_value key metadata
          service_name byte_size updated_at
        ]
      end
    end
  end
end
