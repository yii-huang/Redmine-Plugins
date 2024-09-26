# encoding: utf-8
#
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

# encoding: utf-8
require File.expand_path('../../../test_helper', __FILE__)

class ThumbnailTest < ActiveSupport::TestCase
  def setup
    Redmine::Thumbnail.stubs(:convert_available?).returns(true)
  end

  def test_should_generate_thumbnail_using_system_command
    source = '/tmp/source.png'
    destination = '/tmp/destination.png'

    RedmineContacts::Thumbnail.expects(:system).with("'convert' '/tmp/source.png' -resize '64x64^' -sharpen '0.7x6' -gravity center -extent '64x64' '/tmp/destination.png'").returns(true)
    RedmineContacts::Thumbnail.generate(source, destination, 64)
  end
end
