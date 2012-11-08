require_relative 'admin'

p4port = prompt 'p4port', ENV['P4PORT']
user = prompt 'user'
email = prompt 'email'
password = prompt 'password'

protect  = %x[p4 -p #{p4port} protect -o].gsub(/^.+write user \* \* \/\/\.\.\./, '') + '\n'
protect += '\t' + "write user #{user} * //depot/app-config-app/..." + '\n\n'
protect += '\twrite user sally-runtime * //depot/app-config-app/prod/...\n\n'
protect += '\tread user sally-runtime * //depot/app-config-app/stage/...\n\n'
protect += '\tread user sally-runtime * //depot/app-config-app/dev/...\n\n'
protect += '\twrite user joe-developer * //depot/app-config-app/dev/...\n\n'
protect += '\twrite user jimmy-qa * //depot/app-config-app/stage/...\n\n'
protect += '\tread user jimmy-qa * //depot/app-config-app/dev/...\n\n'

puts %x[echo "#{protect}" | p4 -p #{p4port} protect -i]

useradd p4port, user, email, password

branch user, password, 'stage', 'dev'
branch user, password, 'prod', 'stage'

useradd p4port, 'sally-runtime', 'sally@test.com', 'bananas'
useradd p4port, 'joe-developer', 'joe@test.com', 'oranges'
useradd p4port, 'jimmy-qa', 'jimmy@test.com', 'apples'