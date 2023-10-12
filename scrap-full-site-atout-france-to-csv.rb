# frozen_string_literal: true

# Gemmes / plugins utilisés pour la suite du script
require 'open-uri'
require 'nokogiri'
require 'csv'

# Méthode pour extraire les informations d'une page donnée
def extract_hotel_info(doc)
  hotel_info = []

  doc.css('.facility-detail--wrapper').each_with_index do |wrapper, _index|
    hotel_name = wrapper.at('.facility-detail-title span')&.text || 'Nom non disponible'
    category = wrapper.at('.facility-detail-lead .svg--hotel')&.next&.text || 'Catégorie non disponible'
    stars = wrapper.css('.rate-wrapper svg').size
    address_lines = wrapper.at('.facility-detail-lead i.iconq-location')&.parent&.text&.split('-')&.map(&:strip) || ['Adresse non disponible']
    address_parts = address_lines.map { |part| part.gsub(/[\n\s]+/, ' ').strip }
    address = address_parts.join(' ')
    phone = wrapper.at('.facility-detail-link.facility-detail-phone .info-wrapper div:last-child')&.text || 'Non disponible'
    site = wrapper.at('.facility-detail-link.facility-detail-site .info-wrapper div:last-child')&.text || 'Non disponible'
    email = wrapper.at('.facility-detail-link.facility-detail-mail .info-wrapper div:last-child')&.text || 'Non disponible'

    hotel_info << {
      name: hotel_name,
      category: category.strip,
      stars: "#{stars} étoiles",
      address: address.strip,
      phone:,
      site:,
      email:
    }
  end

  hotel_info
end

# L'URL de base du site
base_url = 'https://www.classement.atout-france.fr/recherche-etablissements'

# Paramètres de recherche
facility_search_params = {
  p_p_id: 'fr_atoutfrance_classementv2_portlet_facility_FacilitySearch',
  p_p_lifecycle: '0',
  p_p_state: 'normal',
  p_p_mode: 'view',
  _fr_atoutfrance_classementv2_portlet_facility_FacilitySearch_performSearch: '1',
  _fr_atoutfrance_classementv2_portlet_facility_FacilitySearch_facility_type: '1',
  _fr_atoutfrance_classementv2_portlet_facility_FacilitySearch_request_ranking: '7',
  _fr_atoutfrance_classementv2_portlet_facility_FacilitySearch_is_luxury_hotel: 'no'
}

hotel_info = []

# Itérer sur les pages en remplaçant le numéro de page
page_number = 1
loop do
  # Construire l'URL avec le numéro de page actuel
  escaped_params = facility_search_params.map { |k, v| "#{k}=#{URI.encode_www_form_component(v)}" }.join('&')
  url = "#{base_url}?#{escaped_params}&_fr_atoutfrance_classementv2_portlet_facility_FacilitySearch_page=#{page_number}"

  # Utilisation d'open-uri pour récupérer le HTML de la page actuelle
  html_content = URI.open(url).read

  # Utilisation de Nokogiri pour analyser le contenu HTML de la page actuelle
  doc = Nokogiri::HTML(html_content)

  # Extraire les informations de la page actuelle
  current_page_hotel_info = extract_hotel_info(doc)

  # Ajouter les informations de la page actuelle au tableau global
  hotel_info.concat(current_page_hotel_info)

  # Identifier si une page suivante existe
  # Vérifier la présence d'une balise <span>30</span> pour la dernière page
  last_page_span = doc.at('span:contains("30")')
  break if last_page_span

  # Incrémenter le numéro de page pour passer à la suivante
  page_number += 1
end

# Nom du fichier dans lequel écrire les informations
output_file = 'hotel_info.csv'

# Ouvrir le fichier CSV en mode écriture et écrire les informations
CSV.open(output_file, 'w', write_headers: true, headers: hotel_info.first.keys) do |csv|
  hotel_info.each do |info|
    csv << info.values
  end
end

puts "Les informations des hôtels ont été enregistrées dans le fichier '#{output_file}'"
