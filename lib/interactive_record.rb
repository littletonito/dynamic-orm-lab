require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  
    def self.table_name
        "#{self.to_s.downcase}s"
    end

    def self.column_names
      #we need to get the table info. PRAGMA gets us that in a hash from which we store in our sql
      #then we connect and execute our sql, which will give us array that we store in a table_info  
        sql = "PRAGMA table_info('#{table_name}')"
        table_info = DB[:conn].execute(sql)
      #then we create an empty array so that we can extract info anf shove into it
        column_names = []
      #we then iterate over our stored array table_info to get the names and then shove them into the empty array  
        table_info.each do |column|
            column_names << column["name"]
        end
      #then we compact to get rif of any nil values  
        column_names.compact
    end

    def initialize(options={})
    #here we use a hash as an argument cuz we expect .new to always be a hash
    #we iterate over the hash and use the send method
    #to interpolate the name of each hash key as a method that we set equal to that key's value
       options.each do |property, value|
           self.send("#{property}=" , value)
       end
    end
    
    #to access the table name we want to INSERT into from inside our #save method
    def table_name_for_insert
      self.class.table_name
    end

    #to get the column names for insert (id, name, grade) but we dont want the id, thats why we delete it
    def col_names_for_insert
      self.class.column_names.delete_if { |col_name| col_name == "id"}.join(", ")
    end

    #iterate over the column names stored in #column_names and use the #send method with each individual column name 
    #to invoke the method by that same name and capture the return value
    def values_for_insert
      values = []
    #we push the return value of invoking a method via the #send method, 
    #unless that value is nil (as it would be for the id method before a record is saved
      self.class.column_names.each do |val|
        values << "'#{send(val)}'" unless send(val).nil?
    #this will return an array but we need a string
      end
      values.join(", ")
    end

    def save
      sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
      DB[:conn].execute(sql)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
      sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
      DB[:conn].execute(sql)
    end

    def self.find_by(attribute_hash)
      value = attribute_hash.values.first
      formatted_value = value.class == Fixnum ? value : "'#{value}'"
      sql = "SELECT * FROM #{self.table_name} WHERE #{attribute_hash.keys.first} = #{formatted_value}"
      DB[:conn].execute(sql)
    end


end