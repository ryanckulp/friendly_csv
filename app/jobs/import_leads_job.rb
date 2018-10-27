class ImportLeadsJob
  include SuckerPunch::Job

  COMPANY_LEGALESE = [', co.', ' co.', ' co',
                      ', Co.', ' Co.', ' Co',
                      '.COM.', '.COM', '.Com.', '.Com', '.com.', '.com',
                      ', corp.', ' corp.', ' corp',
                      ', Corp.', ' Corp.', ' Corp',
                      ', inc.', ' inc.', ' inc',
                      ', Inc.', ' Inc.', ' Inc', ', INC.', ', INC', 'INC.', 'INC',
                      ' KS,', ' Ks,',
                      ', Limited.', ', Limited', ' Limited', ', limited.', ', limited', ' limited',
                      ', llc.', ' llc.', ' llc', ', l.l.c.', ' l.l.c.', ' l.l.c',
                      ', LLC.', ' LLC.', ' LLC', ', L.L.C.', ' L.L.C.', ' l.l.c', ', Llc.', ' Llc.', ', Llc', ' Llc',
                      ', ltd.', ' ltd.', ' ltd', ', l.t.d.', ' l.t.d.', ' l.t.d', ', l.td.', ' l.td.', ' l.td',
                      ', LTD.', ' LTD.', ' LTD', ', Ltd.', ', Ltd', ',Ltd.', ', L.T.D.', ' L.T.D.', ' L.T.D', ', L.td.', ' L.td.', ' L.td', ',Ltd,', ',Ltd', ' Ltd',
                      ' N.A.',
                      ', pty.', ' pty.', ' pty', ', PTY.', ' PTY.', ' PTY', ', Pty.', ' Pty.', 'Pty',
                      ' Sps', ' SPS', ' Sss',
                      ' (USA)', ' (usa)', '(USA)', '(usa)', ' (U.S.A.)', ' (Usa)', ' Usa',
                      '  ', ', ', ' ,', ','
                      ]

  # could be used to update incorrectly titleized names
  # NAME_ACRONYMS = ['AJ', 'aj',
  #                  'BJ', 'bj',
  #                  'CJ', 'cj',
  #                  'DJ', 'dj',
  #                  'TJ', 'tj'
  #                 ]

  def perform(file, batch_id, raw_lead = {}, sanitized_lead = {})
    errors = 0
    duplicates = 0

    CSV.foreach(file.path, headers: true, encoding:'iso-8859-1:utf-8', skip_blanks: true, skip_lines: /^(?:,\s*)+$/) do |row|
      row.to_hash.each_pair { |k,v| raw_lead.merge!({k.strip => v})}

      if no_email_found?(raw_lead)
        errors += 1 # should store each error type separately
        next
      end

      prepare_name(raw_lead, sanitized_lead)
      prepare_email(raw_lead, sanitized_lead)

      if lead_already_exists?(sanitized_lead, batch_id)
        duplicates += 1
        next
      end

      prepare_company(raw_lead, sanitized_lead)
      sanitize_company(sanitized_lead)

      lead_params = {
        batch_id: batch_id,
        first_name: sanitized_lead['first_name'],
        company_name: sanitized_lead['company_name'].strip,
        email_address: sanitized_lead['email_address'],
        extended: stash_extended(raw_lead)
      }

      begin
        Lead.create!(lead_params)
      rescue
        errors += 1
      end
    end

    Batch.find(batch_id).update(error_count: errors, duplicate_count: duplicates)
  end

  def no_email_found?(raw)
    email = !!raw['Email'] || !!raw['Email Address'] || !!raw['Email_Address'] || !!raw['email'] || !!raw['email address'] || !!raw['email_address']
    !email
  end

  def lead_already_exists?(sanitized, batch_id)
    batch = Batch.find(batch_id)
    lead = batch.leads.find_by(email_address: sanitized['email_address'])
    lead.present?
  end

  def prepare_name(raw, sanitized)
    first_name = case
                  when !!raw['contact'] && raw['contact'].length > 1
                    raw['contact'].split[0]
                  when !!raw['first'] && raw['first'].length > 1
                    raw['first'].split[0]
                   when !!raw['first name'] && raw['first name'].length > 1
                     raw['first name'].split[0]
                   when !!raw['first_name'] && raw['first_name'].length > 1
                     raw['first_name'].split[0]
                   when !!raw['Full Name'] && raw['Full Name'].length > 1
                     full_name_array = raw['Full Name'].split
                     full_name_array.delete_at(0) if full_name_array.first.length
                     full_name_array[0]
                   when !!raw['full name'] && raw['full name'].length > 1
                     full_name_array = raw['full name'].split
                     full_name_array.delete_at(0) if full_name_array.first.length
                     full_name_array[0]
                   when !!raw['full_name'] && raw['full_name'].length > 1
                     full_name_array = raw['full_name'].split
                     full_name_array.delete_at(0) if full_name_array.first.length
                     full_name_array[0]
                   when !!raw['name'] && raw['name'].length > 1
                     raw['name'].split[0]
                   when !!raw['Name'] && raw['Name'].length > 1
                     raw['Name'].split[0]
                   when !!raw['person'] && raw['person'].length > 1
                     raw['person'].split[0]
                 end

    sanitized['first_name'] = first_name.nil? ? 'there' : first_name.titleize
  end

  def prepare_email(raw, sanitized)
    email_address = case
                      when !!raw['Email'] && raw['Email'].length > 1
                        raw['Email']
                      when !!raw['Emails'] && raw['Emails'].length > 1 # builtwith.com format
                        raw['Emails'].try(:split, ';').try(:first)
                      when !!raw['Email Address'] && raw['Email Address'].length > 1
                        raw['Email Address']
                      when !!rawimport_leads_job.rb['email'] && raw['email'].length > 1
                        raw['email']
                      when !!raw['email address'] && raw['email address'].length > 1
                        raw['email address']
                      when !!raw['email_address'] && raw['email_address'].length > 1
                        raw['email_address']
                    end

    sanitized['email_address'] = email_address.try(:downcase).try(:strip)
  end

  def prepare_city(raw, sanitized)
    city = case
            when !!raw['city'] && raw['city'].length > 1
              raw['city']
            when !!raw['city name'] && raw['city name'].length > 1
              raw['city name']
          end

    sanitized['city'] = city.nil? ? 'your city' : city.titleize
  end

  def prepare_company(raw, sanitized)
    company_name = case
                      when !!raw['company'] && raw['company'].length > 1
                        raw['company']
                      when !!raw['company name'] && raw['company name'].length > 1
                        raw['company name']
                      when !!raw['copmany name'] && raw['copmany name'].length > 1 # people make typos
                        raw['copmany name']
                      when !!raw['company_name'] && raw['company_name'].length > 1
                        raw['company_name']
                      when !!raw['business'] && raw['business'].length > 1
                        raw['business']
                      when !!raw['business name'] && raw['business name'].length > 1
                        raw['business name']
                      when !!raw['business_name'] && raw['business_name'].length > 1
                        raw['business_name']
                      when !!raw['Office Name'] && raw['Office Name'].length > 1
                        raw['Office Name']
                    end

    if company_name.nil?
      company_name = 'your company'
    else
      company_name = company_name.gsub(/\b\w/, &:capitalize)
    end

    sanitized['company_name'] = company_name
  end

  def sanitize_company(sanitized)
    return if sanitized['company_name'] == 'your company' # default value

    COMPANY_LEGALESE.each do |legalese|
      sanitized['company_name'].gsub!(legalese, '')
    end

    if sanitized['company_name'] == sanitized['company_name'].upcase
      sanitized['company_name'] = sanitized['company_name'].titleize
    else
      sanitized['company_name'] = sanitized['company_name'].gsub(/\b\w/, &:capitalize)
    end
  end

  def stash_extended(raw)
    raw.except('first_name', 'first name', 'full_name', 'full name', 'name', 'business', 'business_name', 'company', 'company_name', 'email', 'email_address', 'email address')
  end

end
