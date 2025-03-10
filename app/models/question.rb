class Question < ApplicationRecord
  belongs_to :form, required: true
  belongs_to :form_section, required: true
  has_many :question_options, dependent: :destroy

  validates :question_type, presence: true
  validate :validate_question_types
  validates_uniqueness_of :answer_field, scope: :form_id

  default_scope { order(position: :asc) }
  scope :ordered, -> { order(position: :asc) }

  MAX_CHARACTERS = 100000

  QUESTION_TYPES = [
    # Standard elements
    "text_field",
    "text_email_field",
    "text_phone_field",
    "textarea",
    "checkbox",
    "radio_buttons",
    "dropdown",
    # Custom elements
    "text_display",
    "custom_text_display",
    "states_dropdown",
    "star_radio_buttons",
    "thumbs_up_down_buttons",
    "yes_no_buttons",
    "hidden_field"
  ]

  validates :answer_field, presence: true
  validates :character_limit, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_CHARACTERS, allow_nil: true }

  after_commit do |question|
    FormCache.invalidate(question.form.short_uuid)
  end

  def max_length
  	return character_limit if character_limit.present?
  	MAX_CHARACTERS
  end

  def validate_question_types
    if !QUESTION_TYPES.include?(question_type)
      errors.add(:question_type, "Invalid question type '#{question_type}'. Valid types include: #{QUESTION_TYPES.to_sentence}.")
    end
  end
end
