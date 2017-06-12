class ImportLeadsJob
  include SuckerPunch::Job

  COMPANY_LEGALESE = [', co.', ' co.', ' co',
                      ', Co.', ' Co.', ' Co',
                      '.COM.', '.Com.', '.Com', '.com.', '.com',
                      ', corp.', ' corp.', ' corp',
                      ', Corp.', ' Corp.', ' Corp',
                      ', inc.', ' inc.', ' inc',
                      ', Inc.', ' Inc.', ' Inc',
                      'KS, ', 'KS,',
                      ', Limited.', ', Limited', ' Limited', ', limited.', ', limited', ' limited',
                      ', llc.', ' llc.', ' llc', ', l.l.c.', ' l.l.c.', ' l.l.c',
                      ', LLC.', ' LLC.', ' LLC', ', L.L.C.', ' L.L.C.', ' l.l.c', ', Llc.', ' Llc.', ', Llc', ' Llc',
                      ', ltd.', ' ltd.', ' ltd', ', l.t.d.', ' l.t.d.', ' l.t.d', ', l.td.', ' l.td.', ' l.td',
                      ', LTD.', ' LTD.', ' LTD', ', Ltd.', ', Ltd', ',Ltd.', ', L.T.D.', ' L.T.D.', ' L.T.D', ', L.td.', ' L.td.', ' L.td', ',Ltd,', ',Ltd', ' Ltd',
                      ', pty.', ' pty.', ' pty',
                      ', PTY.', ' PTY.', ' PTY', ', Pty.', ' Pty.', 'Pty',
                      ' (USA)', ' (usa)', '(USA)', '(usa)'
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
      row.to_hash.each_pair { |k,v| raw_lead.merge!({k.downcase.strip => v})}

      if no_email_found?(raw_lead)
        errors += 1 # should store each error type separately
        break
      end

      prepare_name(raw_lead, sanitized_lead)
      prepare_email(raw_lead, sanitized_lead)

      if lead_already_exists?(sanitized_lead, batch_id)
        duplicates += 1
        break
      end

      prepare_company(raw_lead, sanitized_lead)
      sanitize_company(sanitized_lead)

      lead_params = {
        batch_id: batch_id,
        first_name: sanitized_lead['first_name'],
        company_name: sanitized_lead['company_name'],
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
    email = !!raw['email'] || !!raw['email address'] || !!raw['email_address']
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
                   when !!raw['full name'] && raw['full name'].length > 1
                     raw['full name'].split[0]
                   when !!raw['full_name'] && raw['full_name'].length > 1
                     raw['full_name'].split[0]
                   when !!raw['name'] && raw['name'].length > 1
                     raw['name'].split[0]
                   when !!raw['person'] && raw['person'].length > 1
                     raw['person'].split[0]
                 end

    sanitized['first_name'] = first_name.nil? ? 'there' : first_name.titleize
  end

  def prepare_email(raw, sanitized)
    email_address = case
                      when !!raw['email'] && raw['email'].length > 1
                        raw['email']
                      when !!raw['email address'] && raw['email address'].length > 1
                        raw['email address']
                      when !!raw['email_address'] && raw['email_address'].length > 1
                        raw['email_address']
                    end

    sanitized['email_address'] = email_address.downcase
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
                    end

    sanitized['company_name'] = company_name.nil? ? 'your company' : company_name.titleize
  end

  def sanitize_company(sanitized)
    COMPANY_LEGALESE.each do |legalese|
      sanitized['company_name'].gsub!(legalese, '')
    end
  end

  def stash_extended(raw)
    raw.except('first_name', 'first name', 'full_name', 'full name', 'name', 'business', 'business_name', 'company', 'company_name', 'email', 'email_address', 'email address')
  end

end
