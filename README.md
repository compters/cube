Cube
================

Use this gem talk to the OLAP based backend via XMLA SOAP messages from Ruby.
You can send (simple) MDX queries and get the result back in a human friendly from. 

Installation
------------
Add to Gemfile

```
gem 'cube'
```

Configuration
--------------
Set up your catalog and endpoint

```
XMLA.configure do |c|
 c.catalog = "GOSJAR"
 c.endpoint = "http://localhost:8282/icCube/xmla"
end
```

Queriying the OLAP
-------
```
table = XMLA::Cube.execute <<-MDX
    SELECT [Location].[City].children  on COLUMNS,
           [Measures].[Count] on ROWS
    FROM [GOSJAR]"
MDX
```

Scalar results
-----------
```
result = XMLA::Cube.execute_scalar <<-MDX
   SELECT {Hierarchize({[Measures].[MTBF]})} ON COLUMNS
   FROM [Outage]
   WHERE [Country].[Croatia]
MDX
```
This returns decimal value.

Limitations
------------
* No drill down (fails to even parse the result)
* No multi named columns
* Tested only with icCube and Mondrian XMLA, in theory works with every XMLA provider

Contributing to cube
-------------------------------
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright
----------

Copyright (c) 2012 drKreso. See LICENSE.txt for
further details.

