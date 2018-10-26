import os
import subprocess

MQL4_LOG = 'mql4.log'
COMPILER_PATH = 'D:\\Program Files (x86)\\FXCM MetaTrader 4\\metaeditor.exe'
MQL4_FILE = 'tre_boll_trend.mq4'


class Mql4compileCommand():
    def __init__(self):
        self.compilerpath = COMPILER_PATH
        self.mql4filepath = MQL4_FILE
        self.mql4logpath = MQL4_LOG

    def run(self):
        if self.errorcheck():
            return

        self.runmql4compiler()
        # self.openlog()

    def errorcheck(self):
        iserror = False

        if not os.path.exists(self.compilerpath):
            print('%s | metaeditor.exe is not found' % (COMPILER_PATH))
            iserror = True

        return iserror

    def runmql4compiler(self):
        cmd = '\"%s\" /compile:\"%s\" /log:\"%s\"' % (self.compilerpath,
                                                      self.mql4filepath,
                                                      self.mql4logpath)
        return subprocess.call(cmd, shell=True)

    # def openlog(self):
    #     window = self.view.window()
    #     return window.open_file(MQL4_LOG)


if __name__ == '__main__':
    cmd = Mql4compileCommand()
    cmd.run()
