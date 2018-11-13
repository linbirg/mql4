import os
import subprocess


COPY_SRC = 'D:\\project\\DL\\fxmx\\lin_ea\\*'
# COPY_DIST = 'C:\\Users\\linbirg\\AppData\\Roaming\\MetaQuotes\\Terminal\\C0F4696FA5B2EFDD55586C5E761C530D\\MQL4\\Experts\\lin_ea'
COPY_DIST = 'C:\\Users\\linbirg\\AppData\\Roaming\\MetaQuotes\\Terminal\\DA3C92B1779898CC0CACD726A655BECB\\MQL4\\Experts\\lin_ea'

# MQL4_FILE = 'tre_boll_trend.mq4'


class EACopyCommand():
    def __init__(self):
        self.src = COPY_SRC
        self.dist = COPY_DIST
        

    def run(self):
        self.run_cp_cmd()


    def run_cp_cmd(self):
        cmd = 'powershell cp -r -force %s %s' % (self.src, self.dist)
        print(cmd)
        return subprocess.call(cmd, shell=True)
        # return os.system(cmd)


if __name__ == '__main__':
    cmd = EACopyCommand()
    cmd.run()
