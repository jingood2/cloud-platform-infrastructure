#!/usr/bin/env ruby

# Script to scan the kubernetes cluster, looking for pods which are not part of
# a deployment or other replicaset. These are usually manually-created pods,
# often used for port-forwarding to database instances from outside the
# cluster. They prevent nodes from draining when the node-recycler tries to
# replace the oldest node.

require "date"
require "json"
require "open3"
require "pry-byebug"

KUBE_SYSTEM = "kube-system"
SECONDS_PER_DAY = 86400.0
MAX_AGE_IN_DAYS = 4

def main
  # pods = JSON.parse(execute("kubectl get pods --all-namespaces -o json")).fetch("items") # TODO: use this version
  pods = JSON.parse(File.read("pods.json")).fetch("items")

  no_owners = pods
    .find_all { |pod| pod.dig("metadata", "ownerReferences").nil? }
    .find_all { |pod| pod.dig("metadata", "namespace") != "kube-system" }

  binding.pry ; 1

  pp pods
end

def age_in_days(pod)
  startTime = DateTime.parse(pod.dig("status", "startTime"))
  seconds = Time.now.to_i - startTime.to_time.to_i
  seconds / SECONDS_PER_DAY
end

def execute(cmd, can_fail: false)
  log("blue", "executing: #{cmd}")
  stdout, stderr, status = Open3.capture3(cmd)

  unless can_fail || status.success?
    log("red", "Command: #{cmd} failed.")
    puts stderr
    raise
  end

  puts stdout

  [stdout, stderr, status]
end

def log(colour, message)
  colour_code = case colour
  when "red"
    31
  when "blue"
    34
  when "green"
    32
  else
    raise "Unknown colour #{colour} passed to 'log' method"
  end

  puts "\e[#{colour_code}m#{message}\e[0m"
end

main
