require 'sqlite3'

module Connection
  def connection
    if @connection.nil?
      the_filename = BlocRecord.database_filename
      the_connection = SQLite3::Database.new(the_filename)

      @connection = the_connection
    end

    return @connection
  end
end
