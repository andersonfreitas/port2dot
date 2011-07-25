#!/usr/bin/ruby -w

# visualize macports dependencies: http://blog.mro.name/2010/08/visualise-macports-dependencies/
# pipe the result through graphviz, e.g.
# $ ./port-deps2dot.rb | dot -Tpdf -o port-deps.pdf ; open port-deps.pdf

def scan_deps
	pat = /^([^:]+):(.+)$/
	name = ''
	deps = []
	IO.popen('port info --name --pretty --depends installed') do |f|
		f.each_line do |l|
			case l
				when /^--$/
					yield name, deps
					name = ''
					deps = []
				when /^([^:]+):(.+)$/
					if 'name' == "#$1"
						name = "#$2".strip
					else
						deps.concat("#$2".split(/\s*,\s*/))
					end
				else
					raise "Fall-through for '#{l}'"
			end
		end
	end
end

all = {}

scan_deps do |name,deps|
	d = all[name]
	all[name] = d = [] if d.nil?
	deps.collect! {|i| i.strip}
	d.concat deps
	d.sort!
	d.uniq!
end

requested = []
IO.popen("port list requested | awk '{ print $1 }' | uniq") do |f|
  f.each_line do |l|
    requested << l.strip
  end
end

head = <<END_OF_STRING
#!/usr/bin/dot -Tpdf -o port-deps.pdf
/*
	See http://www.graphviz.org/Documentation.php
*/
digraph "port deps" {
	rankdir=LR;
    label="port deps";
    node [style=filled,fillcolor=lightblue,shape=ellipse];
    top_level [shape=point];
END_OF_STRING

puts head

all.keys.sort.each do |name|
	deps = all[name]
	if deps.count > 0
		deps.each {|d| 
		  puts "\t\"#{name}\" -> \"#{d}\";" if not requested.include?(name)
		  puts "\t\"#{name}\" -> \"#{d}\";" if requested.include?(name)
		}
	else
		puts "\t\"#{name}\";" if not requested.include?(name)
		puts "\t\"#{name}\"" if requested.include?(name)
	end
end

foot = <<END_OF_STRING
}
END_OF_STRING

puts foot