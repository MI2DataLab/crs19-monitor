import datetime
import re
import time

import pandas as pd
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.common.exceptions import (ElementClickInterceptedException,
                                        NoSuchWindowException,
                                        WebDriverException)
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.select import Select


class CaptchaException(Exception):
    pass


class Api:
    """
    Wrapper for GISAID search page
    """
    def __init__(self, credentials, log_dir, download_dir='.', headless=True, verbose=True):
        self.log_dir = log_dir
        self.verbose = verbose
        self._init_driver(credentials, download_dir, headless)
    """
    Logging
    """
    def print_log(self, *args, **kwargs):
        if self.verbose:
            print(*args, **kwargs, flush=True)
    def save_snapshot(self):
        name = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S.%f")
        self.driver.save_screenshot(self.log_dir + '/' + name + ".png")
        with open(self.log_dir + '/' + name + '.html', 'w') as html_file:
            html_file.write(self.driver.page_source)
    """
    Init / Close
    """
    def _init_driver(self, credentials, download_dir, headless):
        """
        Initializes firefox driver logged to https://@epicov.org/epi3/
        @param credentials - dict {'login': '<login>', 'pass': '<password>'}
        @param download_dir - path to directory where downloaded files will be saved
        @param headless - if driver should start without graphical interface
        """
        self.print_log("Setting up driver")
        url = "https://@epicov.org/epi3/"

        profile = webdriver.FirefoxProfile()
        profile.set_preference("browser.download.folderList", 2)
        profile.set_preference("browser.download.manager.useWindow", False)
        profile.set_preference("browser.download.dir", download_dir)
        mimetypes = ['application/octet-stream', 'application/x-tar']
        profile.set_preference("browser.helperApps.neverAsk.saveToDisk", ','.join(mimetypes))

        options = webdriver.firefox.options.Options()
        # comment to allow firefox window
        if headless:
            options.add_argument("--headless")

        self.driver = driver = webdriver.Firefox(
            executable_path="./geckodriver",
            firefox_profile=profile,
            options=options
        )

        try:
            driver.get(url)
            time.sleep(3)
            self.wait_for_timer()

            print("Logging in as ", credentials.get('login'))
            # login
            driver.find_element_by_id("elogin").send_keys(credentials.get('login'))
            driver.find_element_by_id("epassword").send_keys(credentials.get('pass'))
            driver.find_element_by_class_name("form_button_submit").click()
            time.sleep(3)
            self.wait_for_timer()

            # navigate to search
            driver.find_elements_by_class_name("sys-actionbar-action")[1].click()
            time.sleep(30)
            self.wait_for_timer()
            time.sleep(15)
            driver.execute_script("document.getElementById('sys_curtain').remove()")

        except Exception as e:
            self.save_snapshot()
            self.close()
            raise e

    def close(self):
        try:
            self.driver.quit()
        except:
            self.print_log('Failed to quit driver')

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        if exc_value is not None:
            self.save_snapshot()
        self.close()

    """
    API methods
    """
    def wait_for_timer(self):
        """
        Sleeps until "sys_timer_img" and "small_spinner" are visible
        """
        time.sleep(2)
        for i in range(3):
            time.sleep(2)
            while self._is_spinning("sys_timer_img") or self._is_spinning("small_spinner"):
                time.sleep(1)

    def set_region(self, region):
        """
        Filters by given region
        """
        if region == '':
            self.print_log('Skipping region selection')
            return
        self.print_log("Setting region to %s" % region, end='   ')

        input_region = self.driver.find_element_by_class_name("sys-event-hook.sys-fi-mark.yui-ac-input")

        total_records_before_filter = self.get_total_records()
        input_region.clear()
        input_region.send_keys(region)
        self.wait_for_timer()
        total_records = self.get_total_records()

        if total_records != 0 and total_records >= total_records_before_filter:
            self.print_log('')  # new line
            raise Exception('Number of records didn\'t changed after filtering by region')
        self.print_log('[Done]')

    def set_date(self, start_date, end_date):
        """
        Filters by given dates
        """
        input_start = self.driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark.hasDatepicker")[2]
        input_end = self.driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark.hasDatepicker")[3]
        total_records_before_filter = self.get_total_records()

        self.print_log("Setting date to %s : %s" % (start_date, end_date), end='   ')
        input_start.clear()
        input_start.send_keys(start_date.strftime('%Y-%m-%d'))

        self.wait_for_timer()

        input_end.clear()
        input_end.send_keys(end_date.strftime('%Y-%m-%d'))

        self.wait_for_timer()
        total_records = self.get_total_records()

        if total_records != 0 and total_records >= total_records_before_filter:
            self.print_log('')  # new line
            raise Exception('Number of records didn\'t changed after filtering by date')
        self.print_log('[Done]')

    def get_total_records(self):
        total_records = self.driver.find_element_by_class_name("sys-datatable-info-left").text
        total_records = int(re.sub(r'[^0-9]*', "", total_records))
        return total_records

    def get_page_table(self):
        pre_num = self.get_page_number()
        page = self.driver.find_element_by_class_name("yui-dt-bd").get_attribute("innerHTML")
        df = pd.read_html(page)[0]
        post_num = self.get_page_number()
        if pre_num != post_num:
            raise Exception('Page has changed during scrapping %s => %s' % (pre_num, post_num))
        # drop column of checkboxes and symbol
        df = df.drop(['Unnamed: 0', 'Unnamed: 6'], axis=1)
        return df

    def get_accesion_ids(self):
        time.sleep(1)
        self.wait_for_timer()

        total_records = self.get_total_records()
        if total_records == 0:
            return []
        if total_records <= 50:
            return self.get_page_table()['Accession ID'].tolist()

        checkbox = self.driver.find_elements_by_xpath("//input[starts-with(@type, 'checkbox')]")[5]
        if checkbox.get_property('checked') is False:
            self.print_log("Checkbox not checked, checking")
            checkbox.click()
            self.wait_for_timer()
        else:
            self.print_log("Checkbox checked from last search", end='   ')
            checkbox.click()
            self.wait_for_timer()
            self.print_log('[unchecked]', end='   ')

            checkbox.click()
            self.wait_for_timer()
            self.print_log('[rechecked]')

        self.driver.find_element_by_xpath(("//button[contains(., 'Select')]")).click()
        self.wait_for_timer()

        self._find_and_switch_to_iframe()
        input_class_name = "sys-event-hook.sys-fi-mark.sys-form-fi-multiline"
        readed_records = self.driver.find_element_by_class_name(input_class_name).text.replace(' ', '').replace('\n', '').split(",")

        if readed_records == ['']:
            readed_records = []

        # each record can be in one of two formats: a) EPI_ISL_XXX b) EPI_ISL_XXX-YYY
        # Firstly remove prefixes and save a) in array of length 1 and b) as array with start and end of range
        readed_records = [[x.replace('EPI_ISL_', '')] if '-' not in x else x.replace('EPI_ISL_', '').split('-') for x in readed_records if len(x) > 0]
        # replace arrays with start and end by range
        readed_records = [x if len(x) == 1 else range(int(x[0]), int(x[1]) + 1) for x in readed_records]
        # flat array and add prefix
        readed_records = ['EPI_ISL_' + str(accession_id) for sublist in readed_records for accession_id in sublist]

        if len(readed_records) != total_records:
            raise Exception("Readed records ({})!= Total records({})".format(len(readed_records), total_records))

        self.print_log("Switching to default_content")
        self.driver.find_element_by_xpath(("//button[contains(., 'Back')]")).click()
        self.wait_for_timer()
        self.driver.switch_to.default_content()

        return readed_records

    def select_accession_ids(self, ids):
        ids_str = ",".join(ids)
        self.driver.find_element_by_xpath(("//button[contains(., 'Select')]")).click()
        time.sleep(3)
        self.wait_for_timer()
        self._find_and_switch_to_iframe()
        ids_input = self.driver.find_element_by_class_name("sys-event-hook.sys-fi-mark.sys-form-fi-multiline")
        ids_input.clear()
        self.driver.execute_script('arguments[0].value=arguments[1]', ids_input, ids_str)
        ids_input.send_keys(' ')
        self.wait_for_timer()
        self.driver.find_element_by_xpath(("//button[contains(., 'OK')]")).click()
        self.wait_for_timer()
        time.sleep(3)
        # TODO : this chunk should be more safe
        try:
            buttons = self.driver.find_elements_by_class_name("sys-form-button")
            if len(buttons) == 4:
                # message dialog
                self.driver.find_element_by_xpath(("//button[contains(., 'OK')]")).click()
                time.sleep(10)
                self.driver.switch_to.default_content()
        except NoSuchWindowException:
            self.driver.switch_to.default_content()
        except WebDriverException:
            self.driver.switch_to.default_content()
        self.wait_for_timer()
        time.sleep(3)

    def start_downloading_augur(self):
        self.wait_for_timer()
        self.driver.find_element_by_xpath(("//button[contains(., 'Download')]")).click()
        self._find_and_switch_to_iframe()

        self.wait_for_timer()
        self.driver.find_element_by_xpath(("//input[@value='augur_input']")).click()
        self.wait_for_timer()

        self.driver.find_element_by_xpath(("//button[contains(., 'Download')]")).click()
        self.wait_for_timer()
        self.driver.switch_to.default_content()

    def start_downloading_fasta(self):
        self.driver.find_element_by_xpath(("//button[contains(., 'Download')]")).click()
        self._find_and_switch_to_iframe()

        self.driver.find_element_by_xpath(("//button[contains(., 'Download')]")).click()
        self.wait_for_timer()
        self.driver.switch_to.default_content()

    def get_filter_options(self, field):
        """
        Return list of available options for given field.
        Would clear value if field is substitutions.
        @param field - one of ['clades', 'variants', 'substitutions']
        """
        if field == 'clades':
            return self.driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark")[8].text.split('\n')
        if field == 'variants':
            return self.driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark")[11].text.split('\n')
        if field == 'substitutions':
            return self._get_substitusions_options()
        return []

    def filter_by_name(self, field, name):
        """
        Sets filter for given field using visible value.
        This function does not check if number of records changed
        @param field - one of ['clades', 'variants', 'substitutions', 'lineages', 'accession_ids']
        """
        selector = self._get_filter_selector(field)

        # First group - supported by select class
        if field in ['clades', 'variants']:
            selector.select_by_visible_text(name)
        # Second group - works like text input
        elif field in ['substitutions', 'lineages', 'accession_ids']:
            selector.clear()
            self.wait_for_timer()
            selector.send_keys(name)
        else:
            raise Exception('Not supported field')
        self.wait_for_timer()

    def filter_by_index(self, field, index):
        """
        Sets filter for given field using index.
        This function does not check if number of records changed
        @param field - one of ['clades', 'variants']
        """
        selector = self._get_filter_selector(field)

        # First group - supported by select class
        if field in ['clades', 'variants']:
            selector.select_by_index(index)
        else:
            raise Exception('Not supported field')
        self.wait_for_timer()

    def get_page_number(self):
        # 4 retries if page num is not rendered
        for i in range(5):
            try:
                return int(self.driver.find_element_by_class_name("yui-pg-current-page.yui-pg-page").text)
            except:
                time.sleep(0.1 * (i + 1))
        raise Exception('Failed to read page number')

    def is_last_page(self):
        return 'href' not in self.driver.find_element_by_class_name("yui-pg-next").get_attribute("outerHTML")

    def go_to_next_page(self):
        pre_num = self.get_page_number()
        self.driver.find_element_by_class_name("yui-pg-next").click()
        self._wait_for_page_change(pre_num, pre_num + 1)

    def go_to_page(self, num):
        pre_num = self.get_page_number()
        button_num = 0 if self.get_page_number() == 2 else 1
        self.driver.execute_script('document.getElementsByClassName("yui-pg-page")[' + str(button_num) + '].setAttribute("page", %s)' % (num,))
        time.sleep(1)
        self.driver.find_elements_by_class_name("yui-pg-page")[button_num].click()
        self._wait_for_page_change(pre_num, num)

    def get_pango(self, row_id):
        table = self.driver.find_element_by_class_name("yui-dt-data")
        row = table.find_elements_by_tag_name("tr")[row_id]
        row.find_elements_by_tag_name("td")[2].click()

        self.wait_for_timer()
        if self._is_captcha_present():
            raise CaptchaException("Captcha")

        self._find_and_switch_to_iframe()
        pango = self.driver.find_elements_by_xpath("//b[contains(text(),'Pango Lineage')]/../following-sibling::td")[0].text

        self.driver.find_element_by_xpath("//button[contains(text(),'Back')]").click()
        self.wait_for_timer()
        self.driver.switch_to.default_content()

        return pango

    """
    Utils methods
    """
    def _get_elem_or_None(self, class_name):
        """
        Returns element by class_name or None if it doesn't exist
        """
        try:
            elem = self.driver.find_element_by_class_name(class_name)
        except:
            elem = None
        return elem

    def _get_elements_or_empty(self, class_name):
        """
        Returns elements by class_name or [] if there is none
        """
        try:
            elems = self.driver.find_elements_by_class_name(class_name)
        except:
            elems = []
        return elems

    def _is_spinning(self, class_name):
        """
        Returns bool if element with class_name is visible
        """
        elems = self._get_elements_or_empty(class_name)
        for elem in elems:
            try:
                if elem is not None and list(elem.rect.values()) != [0, 0, 0, 0]:
                    return True
            except:
                pass
        return False

    def _find_and_switch_to_iframe(self):
        self.print_log("Switching to iframe")
        self.wait_for_timer()
        iframe = self.driver.find_element_by_class_name("sys-overlay-style")
        self.driver.switch_to.frame(iframe)
        time.sleep(1)
        self.wait_for_timer()

    def _action_click(self, element):
        action = ActionChains(self.driver)
        try:
            action.move_to_element(element).perform()
            element.click()
        except ElementClickInterceptedException:
            self.driver.execute_script("document.getElementById('sys_curtain').remove()")
            action.move_to_element(element).perform()
            element.click()
            return False
        return True

    def _get_substitusions_options(self):
        substitusions = self.driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark.yui-ac-input")[4]
        substitusions.clear()
        self.wait_for_timer()
        substitusions.click()
        self.wait_for_timer()
        cont_table_html = self.driver.find_elements_by_class_name("yui-ac-content")[4].get_attribute("innerHTML")
        soup = BeautifulSoup(cont_table_html, features="lxml")
        subs = []
        for elem in soup.findAll('li'):
            if elem['style'] == 'display: none;':
                continue
            subs.append(elem.text)
        return subs

    def _get_filter_selector(self, field):
        if field == 'clades':
            return Select(self.driver.find_element_by_xpath("//select[@class='sys-event-hook sys-fi-mark']"))
        if field == 'variants':
            return Select(self.driver.find_elements_by_xpath("//select[@class='sys-event-hook sys-fi-mark']")[1])
        if field == 'substitutions':
            return self.driver.find_elements_by_xpath("//input[@class='sys-event-hook sys-fi-mark yui-ac-input']")[4]
        if field == 'lineages':
            return self.driver.find_elements_by_class_name("sys-event-hook.sys-fi-mark.yui-ac-input")[3]
        if field == 'accession_ids':
            return self.driver.find_element_by_xpath("//tr//div[contains(text(), 'Accession ID')]/ancestor::tr/ancestor::tr//input[@type = 'text']")
        raise Exception('Not supported field %s' % field)

    def _wait_for_page_change(self, pre_num, expected_num):
        # sleep until gisaid changes next-page attribute and go to next page
        page_loading_counter = 0
        while pre_num == self.get_page_number():
            time.sleep(0.5)
            page_loading_counter += 1
            if page_loading_counter == 120:
                raise Exception("Scrapping same page twice for 60s")

        post_num = self.get_page_number()
        if post_num != expected_num:
            raise Exception("Page has changed to unexpected number %s => %s (expected: %s)" % (pre_num, post_num, expected_num))

    def _is_captcha_present(self):
        cap = "Prove that you are not a robot:"
        elems = self.driver.find_elements_by_xpath("//*[contains(text(),'" + cap + "')]")
        return len(elems) > 0
