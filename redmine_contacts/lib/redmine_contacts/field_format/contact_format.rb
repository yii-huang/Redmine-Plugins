# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2010-2024 RedmineUP
# http://www.redmineup.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

module RedmineContacts
  module FieldFormat
    class ContactFormat < Redmine::FieldFormat::RecordList
      add 'contact'

      self.customized_class_names = nil
      self.multiple_supported = true

      def edit_tag(view, tag_id, tag_name, custom_value, options = {})
        render_contacts_tag(view, tag_id, tag_name, custom_value.custom_field, custom_value.value, options)
      end

      def bulk_edit_tag(view, tag_id, tag_name, custom_field, objects, value, options={})
        render_contacts_tag(view, tag_id, tag_name, custom_field, value, options.merge(skip_add: true)) +
          bulk_clear_tag(view, tag_id, tag_name, custom_field, value)
      end

      def query_filter_options(custom_field, query)
        super.merge(type: name.to_sym)
      end

      def validate_custom_value(_custom_value)
        []
      end

      def set_custom_field_value(custom_field, custom_field_value, value)
        value = value.flatten.reject(&:blank?) if value.is_a?(Array)
        super(custom_field, custom_field_value, value)
      end

      private

      def render_contacts_tag(view, tag_id, tag_name, custom_field, value, options={})
        contacts = Contact.where(id: value).to_a unless value.blank?
        view.select_contact_tag(tag_name, contacts || [], options.merge(id: tag_id,
                                                                        add_contact: !options[:skip_add],
                                                                        class: "contact_cf #{custom_field.multiple ? 'select2_multi_cf' : ''}",
                                                                        include_blank: !custom_field.is_required,
                                                                        multiple: custom_field.multiple))
      end
    end
  end
end
