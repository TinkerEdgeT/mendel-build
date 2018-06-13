#!/usr/bin/python3

import argparse
import subprocess
import xml.etree.ElementTree as ET

def main():
  parser = argparse.ArgumentParser(description='Check out the revisions belonging to a release build.')
  parser.add_argument('-input', type=str, required=True)
  parser.add_argument('-output', type=str, required=True)
  args = parser.parse_args()

  tree = ET.parse(args.input)
  root = tree.getroot()
  for project in root.findall('project'):
    if project.get('remote'):
      print('We don\'t currently handle projects with non-default remotes: ', project.get('name'))
      continue
    path = project.get('path')
    git_output = subprocess.check_output(['git', '-C', path, 'rev-parse', 'HEAD'])
    revision = git_output.decode('utf-8').strip()
    project.set('revision', revision)

  tree.write(args.output)

if __name__ == '__main__':
  main()
