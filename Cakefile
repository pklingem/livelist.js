{print} = require 'sys'
{spawn} = require 'child_process'
fs      = require 'fs'
{exec}  = require 'child_process'

task 'compile', 'build, concat, minify', ->
  invoke 'build'
  invoke 'concat'
  invoke 'minify'

task 'build', 'Build lib/ from src/', ->
  coffee = spawn 'coffee', ['-c', '--bare', '-o', 'lib', 'src']
  coffee.stdout.on 'data', (data) -> print data.toString()
  coffee.stderr.on 'data', (data) -> print data.toString()

task 'concat', 'Merge all generated Javascript files into a single file, maze-all.js', ->
  priorities =
    "lib/utilities.js": 1
    "lib/livelist.js": 2
    "lib/list.js": 3
    "lib/version.js": 4
    "lib/filters.js": 5
    "lib/pagination.js": 6
    "lib/search.js": 7

  sources = ("lib/#{entry}" for entry in fs.readdirSync("lib"))
  sources = sources.sort (a,b) -> (priorities[a] || 10) - (priorities[b] || 10)

  output = fs.openSync("livelist.js", "w")
  for source in sources
    if source.match(/\.js$/)
      fs.writeSync(output, "// ------ #{source} -------\n")
      fs.writeSync(output, fs.readFileSync(source) + "\n")
  fs.closeSync(output)

task 'minify', 'Concat and minify all generated Javascript files using YUICompressor', ->
  exec 'uglifyjs -o livelist.min.js livelist.js', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
