#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'open-uri'
require 'json'
require 'uri'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def json_from(url)
  JSON.parse(open(url).read, symbolize_names: true) 
end


PAGE_EN = 'http://www.assnat.cm/gestionLoisLegislatures/gestionDeputesEN.php?filterscount=0&groupscount=0&pagenum=0&pagesize=200&recordstartindex=0&recordendindex=0&affichageDeputes=true&legislature=%s+Legislative'
PAGE_FR = 'http://www.assnat.cm/gestionLoisLegislatures/sujetsForum.php?filterscount=0&groupscount=0&pagenum=0&pagesize=200&recordstartindex=0&recordendindex=0&affichageDeputes=true&legislature=%s+Legislative'

terms = %w(1st 2nd 3rd 4th 5th 6th 7th 8th 9th)

terms.each do |term|
  url = PAGE_FR % term
  puts "Fetching #{term} Assembly"
  json = json_from(url).first
  next if json[:TotalRows].to_i.zero?
  json[:Rows].sort_by { |r| r[:ID_Depute].to_i }.each do |row|
    data = { 
      id: row[:ID_Depute],
      name: row[:nomPrenom],
      birth_date: row[:dateNaissance],
      email: row[:email],
      area: row[:region],
      party: row[:partiePolitique],
      photo: row[:cheminPhoto].gsub('http://localhost/www.', 'http://www.').to_s,
      term: term[/^(\d+)/, 1],
    }
    data.delete :photo if data[:photo].include? '/vide.jpg'
    data.delete :email unless data[:email].include? '@'
    data.delete :birth_date if data[:birth_date].start_with?('2014') 
    data[:photo] = URI.join(url, URI.escape(data[:photo])).to_s if data.key?(:photo) && !data[:photo].start_with?('http')
    data[:photo] &&= data[:photo].gsub 'gestionLoisLegislatures/gestionLoisLegislatures', 'gestionLoisLegislatures'
    ScraperWiki.save_sqlite([:id, :term], data)
  end
end

