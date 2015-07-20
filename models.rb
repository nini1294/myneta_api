require 'pg'

class PostgresDirect
  # Create the connection instance.
  def connect
    @conn = PG.connect(
                        :host => 'ec2-54-83-20-177.compute-1.amazonaws.com',
                        :port => 5432,
                        :dbname => 'd3volvoen2akce',
                        :user => 'pmyvxrkrgxnvxz',
                        :password => '-sB3vkxwYpPYxLdBvLQyhMsVJc')
  end

  # Create our test table (assumes it doesn't already exist)
  def createUserTable
    @conn.exec("CREATE TABLE users (id serial NOT NULL, name character varying(255), CONSTRAINT users_pkey PRIMARY KEY (id)) WITH (OIDS=FALSE);");
  end

  # When we're done, we're going to drop our test table.
  def dropUserTable
    @conn.exec("DROP TABLE users")
  end

  # Prepared statements prevent SQL injection attacks.  However, for the connection, the prepared statements
  # live and apparently cannot be removed, at least not very easily.  There is apparently a significant
  # performance improvement using prepared statements.
  def prepareInsertUserStatement
    @conn.prepare("insert_user", "insert into users (id, name) values ($1, $2)")
  end

  # Add a user with the prepared statement.
  def addUser(id, username)
    @conn.exec_prepared("insert_user", [id, username])
  end

  # Get our data back
  def queryUserTable
    @conn.exec( "SELECT * FROM users" ) do |result|
      result.each do |row|
        yield row if block_given?
      end
    end
  end

  # Disconnect the back-end connection.
  def disconnect
    @conn.close
  end
end

def hello_db
  p = PostgresDirect.new()
  p.connect
  begin
    # p.createUserTable
    # p.prepareInsertUserStatement
    # p.addUser(1, "Marc")
    # p.addUser(2, "Sharon")
    ret = []
    p.queryUserTable do |row| 
        ret << ("id: #{row['id']}, name: #{row['name']}")
    end
  rescue Exception => e
    puts e.message
    puts e.backtrace.inspect
  ensure
    # p.dropUserTable
    p.disconnect
    return ret;
  end
end
