require 'sqlite3'

module Connection

  def connection
    case BlocRecord.db_type
    when :sqlite
      @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
    when :pg
      @connection ||= PG::Connection.open(dbname: BlocRecord.database_filename)
    else
      raise ArgumentError "That is not a supported database type."
    end
  end
end
