# README


## Purpose


This app provides a scaffold for understanding, testing, and instrumenting various types of rails sessions.


Setup

### Non-Clustered Redis Server

The following steps are required to run this server against a single Redis server:

* Download and install a Redis server (http://redis.io/).
  * The default port for Redis is 6379.
  * This app is configured to connect to Redis via that port on the localhost.
  * This configuration can be changed in the config/initializers/session_store.rb.
  * Redis supports operating multiple databases within the same server by numercially indexing each database. This app will use the database at index 0.
  * This app is configured to connect to the Redis server anonymously.
  * This is not a safe way to operate your Redis server, but is suitable for this type of test app.
* Run the Redis server using the "redis-server" command.
* Run the Rails server using the "rails server" command.


### Cluster of Redis Servers

To setup a Redis cluster to back this server, use the steps outlined at http://redis.io/topics/cluster-tutorial. In addition to this, please be mindful of the following:

* The redis-trib.rb tool depends on the redis gem, so be sure to have that installed.
* I have included the config files I used to setup a cluster in docs/redis/cluster.
  * Prior to using these, please update the docs/redis/redis.conf file to point to your default redis.conf file.
  * After launching all six of these redis instances, you will need to run the following command from the Redis src directory to properly configure the cluster:

        ./redis-trib.rb create --replicas 1 127.0.0.1:7000 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005

* To run multiple Rails servers against these nodes, use commands like the following to explicitly set the port and process ID file for each Rails server:

        rails server -p 3000 -P /tmp/rails-3000.pid
        rails server -p 3001 -P /tmp/rails-3001.pid
        rails server -p 3002 -P /tmp/rails-3002.pid
        rails server -p 3003 -P /tmp/rails-3003.pid
        rails server -p 3004 -P /tmp/rails-3004.pid
        rails server -p 3005 -P /tmp/rails-3005.pid

  * You will need to manually change the Redis server's port before running each of these servers to ensure they are all connecting to different nodes in the Redis cluster.
  * Unfortunately passing this value in as a command line parameter when running the server is not currently supported.
* Unfortunately the redis gem (https://github.com/redis/redis-rb) on which the Redis session store depends does not currently support connecting to a cluster of Redis servers.
  * It does not support the required Redis clustering commands like 'MOVED' or '-ASK'.
  * To verify this you can launch a rails console and run the following set of commands:

require 'redis'
redis = Redis.new(:host => "localhost", :port => 7001, :db => 0)
redis.get(4790)

  * A CommandError will indicate that the MOVED command is not supported.
  * This assumes that the key you requested, '4790' in this example, maps to a slot that does not reside on the Redis server running on port 7001.
  * I would suggest retrieving the same key from all master servers to confirm that clustering support is working properly.


## Helpful Tips

The following tips may prove helpful as you explore and work with Redis sessions:

* To run commands directly in your Redis database use the Redis CLI using the "redis-cli" command.
* Use the following steps to lookup a session directly in Redis:
  * Copy the session ID as shown in the "Session Content" section on the app's root page.
  * Run the following command within the Redis CLI "get <SESSION_ID>", where "<SESSION_ID>" is replaced by the session ID value.
* Be very careful when managing concurrent access to records in your Redis database.
  * As highlighted in the Redis Cluster Specification documentation "Very high performances and scalability while preserving weak but reasonable forms of data safety and availability is the main goal of Redis Cluster."


## Other Resources

The following resources may also prove to be beneficial:

* Redis Cluster Setup: http://redis.io/topics/cluster-tutorial
* Redis Cluster Specification: http://redis.io/topics/cluster-spec
  * If you plan to deploy a redis cluster, I recommend reading this document carefully to ensure you understand the considerations to be taken in setting up and operating this cluster.