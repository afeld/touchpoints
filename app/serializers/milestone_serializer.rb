class MilestoneSerializer < ActiveModel::Serializer
  attributes :id, :organization_id, :name, :description, :due_date, :status, :notes
end
