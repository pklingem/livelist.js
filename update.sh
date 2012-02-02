cp ../livelist-rails/app/assets/javascripts/livelist.coffee .
coffee -c livelist.coffee 
uglifyjs -o livelist.min.js livelist.js
