# frozen_string_literal: true

class ModuleManagerSettingsController < ApplicationController

  def update
    unless params[:enabled_module].blank?
      params[:enabled_module].each do |project_id, modules|
        project = Project.find(project_id)

        params[:all_modules].each do |m|
          modules.include?(m) ? project.enable_module!(m) : project.disable_module!(m)
        end
      end


      flash[:success] =l(:notice_successful_update)
    end

    redirect_to plugin_settings_path('module_manager')
  end

end
