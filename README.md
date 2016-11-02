# FriendlyCSV
sanitize cold email merge variables before you hit send.

don't code? https://friendly-csv.herokuapp.com

### why?

* merging {{ first_name }} but your data says "John Smith"
* merging {{ company_name }} but your data says "Solstice Equity Partners, *Inc.*"
* merging {{ first_name }} but your data says "JIMMY"
* etc.

### getting started

1. `$ rake db:setup && rake db:migrate`
2. `$ rails s`

### todo

1. styles (fonts, buttons, etc)
2. 'how it works' fold on landing
3. analytics
3. let user have leads sent to their email
4. what else?
