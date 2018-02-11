require 'sqlite3'

module Selection

  def find(*ids)
    ids.each do |id|
        unless id.is_a? Integer && id > 0
            raise ArgumentError.new('ID must be a postive integer')
        end
    end
    if ids.length == 1
      find_one(ids.first)
    else
      rows = connection.execute <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        WHERE id IN (#{ids.join(",")});
      SQL

      rows_to_array(rows)
    end
  end

  def find_one(id)
    unless id.is_a? Integer && id > 0
        raise ArgumentError.new('ID must be a postive integer')
    end
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    init_object_from_row(row)
  end

  def find_by(attribute, value)
    unless attribute.is_a? String
      raise.ArgumentError.new('Please enter a string')
    end

    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
    SQL

    init_object_from_row(row)
  end

  def method_missing(m, *args, &block)
    if m.to_s =~ /^find_by_(.*)$/ && columns.include?($1)
      find_by($1.to_sym, args.first)
    else
      raise ArgumentError, "#{$1} is not an existing attribute"
    end
  end

  def find_each(start: 1, batch_size: 1000)
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{start}
      LIMIT #{batch_size}
      SQL
    entries = rows_to_array(rows)
    entries.each{ |e| yield e }
  end

  def find_batch(start, batch_size)
    #find one batch
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      WHERE id = #{start}
      LIMIT #{batch_size}
      SQL
    rows_to_array(rows)
  end

  def find_in_batches(start, batch_size)
    #find out how many records are total
    row = connection.execute <<-SQL
      SELECT count(id) FROM #{table};
    SQL
    max = row[0][0]
    batch_num = 0;
    while start < max do
      # find batch
      entries = find_batch(start, batch_size)
      entries.each{ |e| yield e }
      #increment batch_start, batch_num
      start += batch_size
      batch_num += 1
    end
  end

  def take(num=1)
    if num > 1
      rows = connection.get_first_row <<-SQL
        SELECT #{columns.join ","} FROM #{table}
        ORDER BY random()
        LIMIT #{num};
      SQL

      rows_to_array(rows)
    else
      take_one
    end
  end

  def take_one
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY random()
      LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def first
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id ASC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def last
    row = connection.get_first_row <<-SQL
      SELECT #{columns.join ","} FROM #{table}
      ORDER BY id DESC LIMIT 1;
    SQL

    init_object_from_row(row)
  end

  def all
    rows = connection.execute <<-SQL
      SELECT #{columns.join ","} FROM #{table}
    SQL

    rows_to_array(rows)
  end

  private
  def init_object_from_row(row)
    if row
      data = Hash[columns.zip(row)]
      new(data)
    end
  end

  def rows_to_array(rows)
    rows.map {|row| new(Hash[columns.zip(row)]) }
  end
end
