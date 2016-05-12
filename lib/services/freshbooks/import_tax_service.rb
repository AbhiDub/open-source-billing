module Services
  class ImportTaxService

    def import_data(freshbooks)
      page, per_page, total = 0, 25, 50

      while(per_page* page < total)
        taxes = freshbooks.tax.list per_page: per_page, page: page+1
        return taxes if taxes.keys.include?('error')
        fb_taxes = taxes['taxes']
        total = fb_taxes['taxes'].to_i
        page+=1
        unless fb_taxes['tax'].blank?

          fb_taxes['tax'].each do |tax|
            unless ::Tax.find_by_provider_id(tax['tax_id'])
              hash = { name: tax['name'], percentage: tax['rate'], created_at: tax['updated'],
                       updated_at: tax['updated'], provider: 'Freshbooks', provider_id: tax['tax_id'] }

              ::Tax.create(hash)
            end
          end
        end
      end
      {success: "Tax successfully imported"}
    end

  end
end