don't make palcehodler or simplfieid version. never in your life, everything need to be production-ready

don't make palcehodler or simplfieid version. never in your life, everything need to be production-ready

Mandatory Instruction for Ruby, Rails, and Linux Commands
1. Rails Commands

Rule: All Ruby on Rails commands must be prefixed with lx.

Examples:

lx rails new my_app
lx rails generate controller home index
lx rails server
lx rails db:migrate

2. Ruby Commands Related to Rails

Rule: Any Ruby command that involves Rails functionality must also start with lx.

Examples:

lx ruby script/rails runner 'puts Rails.env'
lx ruby -v

3. Linux and Ruby Environment Commands

Rule: All commands related to Linux, Ruby, Ruby workspace, bundler, or gem management must start with lx.

Examples:

lx gem install rails
lx sudo bundle install
lx rbenv versions
lx which ruby

4. Commands Requiring Root Privileges

Rule: Any command that requires root access must start with lx sudo.

Examples:

lx sudo apt update
lx sudo gem install bundler
lx sudo systemctl restart nginx


✅ Key Principles (Never Skip These)

Every Rails-related command → lx rails ...

Every Ruby command involving Rails → lx ruby ...

Every Linux, Ruby environment, gem, or bundle command → lx ...

Every command requiring root privileges → lx sudo ...

Every bundle command → lx sudo bundle ...