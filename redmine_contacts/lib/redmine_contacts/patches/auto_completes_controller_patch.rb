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

require_dependency 'auto_completes_controller'

module RedmineContacts
  module Patches
    module AutoCompletesControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          include ActionView::Helpers::AssetTagHelper
          include ActionView::Helpers::SanitizeHelper
          include ApplicationHelper
          include Helper::CrmCalendarHelper
          include ERB::Util
        end
      end

      module InstanceMethods
        DEFAULT_LIMIT = 10
        DEFAULT_CONTACTS_LIMIT = 30

        def contact_tags
          @name = params[:q].to_s
          @tags = Contact.available_tags :name_like => @name, limit: DEFAULT_LIMIT
          render json: format_crm_tags_json(@tags)
        end

        def taggable_tags
          klass = Object.const_get(params[:taggable_type].camelcase)
          @name = params[:q].to_s
          @tags = klass.all_tag_counts(:conditions => ["#{Redmineup::Tag.table_name}.name LIKE ?", "%#{@name}%"], :limit => 10)
          render json: format_crm_tags_json(@tags)
        end

        def contacts
          @contacts = []
          q = (params[:q] || params[:term]).to_s.strip
          scope = Contact.includes(:avatar).where({})
          scope = scope.limit(params[:limit] || DEFAULT_CONTACTS_LIMIT)
          scope = scope.companies if params[:is_company]
          scope = scope.joins(:projects).where(Contact.visible_condition(User.current))
          scope = Rails.version >= '5.1' ? scope.distinct : scope.uniq
          q.split(' ').collect { |search_string| scope = scope.live_search(search_string.gsub(/[\(\)]/, '')) } unless q.blank?
          scope = scope.by_project(@project) if @project
          @contacts = scope.to_a.sort! { |x, y| x.name <=> y.name }

          render json: params[:multiaddress] ? format_multiaddress_contacts_json(@contacts) : format_contacts_json(@contacts)
        end

        def companies
          @companies = []
          q = (params[:q] || params[:term]).to_s.strip
          if q.present?
            scope = Contact.joins(:projects).where({})
            scope = scope.limit(params[:limit] || DEFAULT_CONTACTS_LIMIT)
            scope = scope.includes(:avatar)
            scope = scope.by_project(@project) if @project
            scope = scope.where('LOWER(first_name) LIKE LOWER(?)', "%#{q}%") unless q.blank?
            @companies = scope.visible.companies.order("#{Contact.table_name}.first_name")
          end
          render json: format_companies_json(@companies)
        end

        private

        def format_crm_tags_json(tags)
          tags.collect do |tag|
            {
              id: tag.name,
              text: tag.name
            }
          end
        end

        def format_contacts_json(contacts)
          contacts.map do |contact|
            {
              id: contact.id,
              text: contact.name_with_company,
              name: contact.name,
              avatar: avatar_to(contact, size: 16),
              company: contact.is_company ? '' : contact.company,
              email: contact.primary_email,
              value: contact.id
            }
          end
        end

        def format_multiaddress_contacts_json(contacts)
          @contacts.inject([]) do |collector, contact|
            contact_emails = contact.emails.empty? ? [' '] : contact.emails
            collector + contact_emails.map do |email|
              {
                id: email.blank? ? contact.id : email,
                text: contact.name_with_company,
                name: contact.name,
                avatar: avatar_to(contact, size: 32, class: 'select2-contact__avatar'),
                company: contact.is_company ? '' : contact.company,
                email: email,
                value: contact.id
              }
            end
          end
        end

        def format_companies_json(companies)
          companies.map do |company|
            {
              id: company.id,
              name: company.name,
              avatar: avatar_to(company, size: 16),
              email: company.primary_email,
              label: company.name,
              value: company.name
            }
          end
        end
      end
    end
  end
end

unless AutoCompletesController.included_modules.include?(RedmineContacts::Patches::AutoCompletesControllerPatch)
  AutoCompletesController.send(:include, RedmineContacts::Patches::AutoCompletesControllerPatch)
end
