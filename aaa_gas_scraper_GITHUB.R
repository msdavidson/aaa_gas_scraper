library(tidyverse)
library(rvest)
library(lubridate)
library(mailR)
library(rmarkdown)

aaa_nv <- read_html("https://gasprices.aaa.com/?state=NV")

gas_nv <- aaa_nv %>% html_nodes(".table-mob tr:nth-child(1) td") %>%
  html_text()

gas_df <- data.frame(gas_nv)

gas_df <- gas_df %>% 
  mutate(key = rep(c('Price', 'Regular', 'Mid', 'Premium', 'Diesel'), n() / 5), 
         id = cumsum(key == 'Price')) %>% 
  spread(key, gas_nv) %>% 
  select(id, Regular, Mid, Premium, Diesel) %>% 
  mutate(Date = Sys.Date())

gas_df$id[which(gas_df$id == "1")] <- "Nevada"
gas_df$id[which(gas_df$id == "2")] <- "Las_Vegas"
gas_df$id[which(gas_df$id == "3")] <- "Reno"

##
#Make a backup of the full scrape

sys <- format(Sys.time(), "%Y_%m_%d")

sys_path <- paste0("data/NV_", sys, ".csv", collapse = NULL)

write.csv(gas_df, file=sys_path,row.names=FALSE)

##
#Render Word report
docx_report_path <- paste0("data/aaa_", 
                           sys,
                           '.docx', sep='')

rmarkdown::render("aaa_gas_report.Rmd",
                  output_file = docx_report_path)

#Email the output CSVs (Master, and Media Only)
send.mail(from = "lvrjautodata@gmail.com",
          to = c("michaeldmedia@gmail.com"),
          subject = paste0("AAA Scraper NV - Export: ", sys),
          body = "Test GitHub Scraper for AAA Gas Prices",
          smtp = list(host.name = "smtp.gmail.com", port = 465, 
                      user.name = "lvrjautodata", 
                      #Generated app password thru Gmail security settings
                      passwd = "llxgybjlubznaofm", 
                      ssl = TRUE),
          authenticate = TRUE,
          send = TRUE,
          attach.files = c(sys_path, docx_report_path),
          file.names = c("aaa_gas.csv", "aaa_gas.docx"))
