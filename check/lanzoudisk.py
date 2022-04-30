from argparse import ArgumentParser
from lanzou.api import LanZouCloud

if __name__ == '__main__':

    parser = ArgumentParser(prog='lanzoudisk.py',
                            description='Lanzou Disk Checker')
    parser.add_argument('-u', '--url', dest='url',
                        help='url of the folder', required=True)
    parser.add_argument('-p', '--pwd', dest='pwd',
                        help='password of the folder', default='')
    args = parser.parse_args()

    lzy = LanZouCloud()

    # cookie = {'ylogin': os.getenv('LZ_YLOGIN'),
    #           'phpdisk_info': os.getenv('LZ_PHPDISK_INFO')}
    # lzy.login_by_cookie(cookie)

    def get_folder_info_by_url(share_url, dir_pwd):
        """
        Get information about the folder by sharing the link
        :param share_url: folder sharing url, Required. e.g. https://www.lanzou.com/s/1q2w3e4r
        :param dir_pwd: password, Optional. Default is ''.
        :return: folder info
        """
        lzy = LanZouCloud()
        folder_info = lzy.get_folder_info_by_url(share_url, dir_pwd)

        for file in folder_info.files:
            filename: str = file.name
            print(filename)

    get_folder_info_by_url(args.url, args.pwd)
