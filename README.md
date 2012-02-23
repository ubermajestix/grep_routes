Grep Routes
===========
Running `rake routes` is super slow and a waste of time. 

`grep_routes` is similar to `rake routes | grep someroute` but way faster.  

Install
-------

    gem install grep_routes
    
Usage
-----
All commands should be run from the root of your Rails3 project.

Show all your routes:

    grep_routes
    
Grep through your routes:
  
    grep_routes privacy_policy
    
Grep through your routes using regex:

    grep_routes "(privacy_policy|terms|\w+_id)"
    
Reporting Problems
------------------
Please use [Github Issues](https://github.com/ubermajestix/grep_routes/issues) to report any problems. Please include a snippet of your routes.rb file so its easier to diagnose, test, and fix the problem!

Contributing
------------
Fork, code, send pull request.