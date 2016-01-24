module Scrum
  class Setting

    ["create_journal_on_pbi_position_change", "inherit_pbi_attributes", "render_position_on_pbi",
      "render_category_on_pbi", "render_version_on_pbi", "render_author_on_pbi",
      "render_updated_on_pbi", "check_dependencies_on_pbi_sorting",
      "render_pbis_deviations", "render_tasks_deviations"].each do |setting|
      src = <<-END_SRC
      def self.#{setting}
        setting_or_default_boolean(:#{setting})
      end
      END_SRC
      class_eval src, __FILE__, __LINE__
    end

    ["doer_color", "reviewer_color", "blocked_color"].each do |setting|
      src = <<-END_SRC
      def self.#{setting}
        setting_or_default(:#{setting})
      end
      END_SRC
      class_eval src, __FILE__, __LINE__
    end

    ["task_status_ids", "task_tracker_ids", "pbi_status_ids", "pbi_tracker_ids",
      "verification_activity_ids"].each do |setting|
      src = <<-END_SRC
      def self.#{setting}
        collect_ids(:#{setting})
      end
      END_SRC
      class_eval src, __FILE__, __LINE__
    end

    ["story_points_custom_field_id", "blocked_custom_field_id"].each do |setting|
      src = <<-END_SRC
      def self.#{setting}
        ::Setting.plugin_scrum[:#{setting}]
      end
      END_SRC
      class_eval src, __FILE__, __LINE__
    end

    module TrackerFields
      FIELDS = "fields"
      CUSTOM_FIELDS = "custom_fields"
      SPRINT_BOARD_FIELDS = "sprint_board_fields"
      SPRINT_BOARD_CUSTOM_FIELDS = "sprint_board_custom_fields"
    end

    def self.tracker_fields(tracker, type = TrackerFields::FIELDS)
      collect("tracker_#{tracker}_#{type}")
    end

    def self.tracker_field?(tracker, field, type = TrackerFields::FIELDS)
      tracker_fields(tracker, type).include?(field.to_s)
    end

    def self.sprint_board_fields_for_tracker(tracker)
      tracker_fields = tracker_fields(tracker.id, TrackerFields::FIELDS)
      fields = [:status_id]
      fields << :category_id if tracker_fields.include?("category_id")
      fields << :fixed_version_id if tracker_fields.include?("fixed_version_id")
      return fields
    end

    def self.task_tracker
      Tracker.all(task_tracker_ids)
    end

    def self.tracker_id_color(id)
      setting_or_default("tracker_#{id}_color")
    end

    def self.product_burndown_sprints
      setting_or_default_integer(:product_burndown_sprints, :min => 1)
    end

    def self.major_deviation_ratio
      setting_or_default_integer(:major_deviation_ratio, :min => 101, :max => 1000)
    end

    def self.minor_deviation_ratio
      setting_or_default_integer(:minor_deviation_ratio, :min => 101, :max => 1000)
    end

    def self.below_deviation_ratio
      setting_or_default_integer(:below_deviation_ratio, :min => 0, :max => 99)
    end

    private

    def self.setting_or_default(setting)
      ::Setting.plugin_scrum[setting] ||
      Redmine::Plugin::registered_plugins[:scrum].settings[:default][setting]
    end

    def self.setting_or_default_boolean(setting)
      setting_or_default(setting) == "1"
    end

    def self.setting_or_default_integer(setting, options = {})
      value = setting_or_default(setting).to_i
      value = options[:min] if options[:min] and value < options[:min]
      value = options[:max] if options[:max] and value > options[:max]
      value
    end

    def self.collect_ids(setting)
      (::Setting.plugin_scrum[setting] || []).collect{|value| value.to_i}
    end

    def self.collect(setting)
      (::Setting.plugin_scrum[setting] || [])
    end

  end
end
