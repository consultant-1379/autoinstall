#Author: Eimhin Smyth
#Date: 22/03/2017

import sys

#removes bash wildcards
def clean(s):
	s = s.replace('#', '')
	strip_chars = s[s.find("["):]
	return s.replace(strip_chars, "")

#finds variables expected by the deployment script, assumes
#they take the form ${FOO}
def script_var_finder(var_list, line):
	line = line.lstrip()
	#ignores comments and empty lines
	if line[:1] == '#' or line == '\n':
		return var_list
	if "${" in line:
		var_list.append(line[line.find("${") + 2 : line.find("}")])
		if "${" in line[line.find("${") + 2:]:
			var_list = script_var_finder(var_list, line[line.find("}")+1:])
	return var_list

#finds properties defined in the cluster file
def cluster_reader(var_list, line):
	if line[:1] == '#' or line == '\n':
		return var_list
	elif "=" in line:
		var_list.append(line[:line.find("=")])
	return var_list

#finds variables in the deployment script that aren't meant to be in the cluster file, 
#i.e variables defined in the script. Assumes FOO occurs in a line like"declare -* FOO=...."
def build_ignore_list(i_list, line):
	line = line.lstrip()
	if line[:7] == 'declare':
		i_list.append(line[11:line.find('=')])
	return i_list

#Opens deployment script and cluster file, paths
#provided at command line
deployment_script = open(sys.argv[1])
cluster_file = open(sys.argv[2])

#list of vars to be ignored, vars expected by delpoyment script
#and properties set in the cluster file
ignore_list = []
script_vars = []
cluster_vars = []

#populates above lists from deployment script
for line in deployment_script:
	ignore_list = build_ignore_list(ignore_list, line)
	script_vars = script_var_finder(script_vars, line)

#populates list of properties set in the cluster file
for line in cluster_file:
	cluster_vars = cluster_reader(cluster_vars, line)

#filters indexing vars from deployment script, assumes they look like
#${i} or ${j}
script_vars = filter(lambda a: a != "i", script_vars)
script_vars = filter(lambda a: a != "j", script_vars)

#goes through all vars from deployment script, removing those defined in the
#cluster file and those added to the ignore list
for var in script_vars:
	for item in ignore_list:
		if item == var[:len(item)]:
			script_vars = filter(lambda a: a != var, script_vars)
			break
	for cluster_value in cluster_vars:
		if var == cluster_value:
			script_vars = filter(lambda a: a != var, script_vars)
			#print "got here"
			#break
		if ('#' or '@' or '$i' in var) and clean(var) == clean(cluster_value):
			#print var + ":" + cluster_value
			script_vars = filter(lambda a: a != var, script_vars)
			break

#prints out any remaning items in script_vars. Anything still in this list
#is expected in the deployment script but not found in the cluster file.
for var in script_vars:
	print var

#closes both files.
deployment_script.close()
cluster_file.close()