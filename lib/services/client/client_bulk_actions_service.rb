#
# Open Source Billing - A super simple software to create & send invoices to your customers and
# collect payments.
# Copyright (C) 2013 Mark Mian <mark.mian@opensourcebilling.org>
#
# This file is part of Open Source Billing.
#
# Open Source Billing is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Open Source Billing is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Open Source Billing.  If not, see <http://www.gnu.org/licenses/>.
#
module Services
  class ClientBulkActionsService
    attr_reader :clients, :client_ids, :options, :action_to_perform

    def initialize(options)
      actions_list = %w(archive destroy recover_archived recover_deleted)
      @options = options
      @action_to_perform = actions_list.map { |action| action if @options[action] }.compact.first #@options[:commit]
      @client_ids = @options[:client_ids]
      @clients = ::Client.multiple(@client_ids)
      @current_user = @options[:current_user]
    end

    def perform
      method(@action_to_perform).call.merge({client_ids: @client_ids, action_to_perform: @action_to_perform})
    end

    def archive
      @clients.map(&:archive)
      {action: 'archived', clients: get_clients('unarchived')}
    end

    def destroy
      @clients.map(&:destroy)
      {action: 'deleted', clients: get_clients('unarchived')}
    end

    def recover_archived
      @clients.map(&:unarchive)
      {action: 'recovered from archived', clients: get_clients('archived')}
    end

    def recover_deleted
      @clients.only_deleted.map { |client| client.recover; client.unarchive }
      {action: 'recovered from deleted', clients: get_clients('only_deleted')}
    end

    private

    def get_clients(filter)
      ::Client.get_clients(@options.merge(status: filter)) #(filter).page(@options[:page]).per(@options[:per])
    end
  end
end
