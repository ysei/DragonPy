# coding: utf-8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================
    
    :created: 2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2014-2015 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
end
"""

require __future__

require zipfile
require logging
require hashlib
require os
require sys

PY3 = sys.version_info[0] == 3
if PY3
    from urllib.request import urlopen
    require zipfile
else
    require urllib2
    require zipfile
end

require dragonpy


ARCHIVE_EXT_ZIP = ".zip"

log = logging.getLogger(__name__)


class ROMFileNotFound < Exception
    pass
end


class ROMFile < object
    ROM_PATH=os.path.normpath(
        os.path.join(os.path.abspath(os.path.dirname(dragonpy.__file__)), "..", "roms")
    end
    )
    URL = nil # download location
    DOWNLOAD_SHA1 = nil # Hash of the downloaded file
    ARCHIVE_EXT = ARCHIVE_EXT_ZIP # archive type of the download
    FILE_COUNT = nil # how many files are in the archive?
    RENAME_DATA = nil # save the files with different names from archive
    
    SHA1 = nil # Hash of the extracted ROM file
    FILENAME = nil # filename of the ROM file, e.g.: "d32.rom"
    
    def initialize (address, max_size=nil)
        @address = address
        @max_size = max_size
        
        if not os.path.isdir(@ROM_PATH)
            os.makedirs(@ROM_PATH)
            print("ROM path created here: %r" % @ROM_PATH)
        else
            log.debug("Use ROM path: %r" % @ROM_PATH)
        end
        
        @archive_filename = @FILENAME + @ARCHIVE_EXT # used to download
        @archive_path = os.path.join(@ROM_PATH, @archive_filename)
        @rom_path=os.path.join(@ROM_PATH, @FILENAME)
    end
    
    def get_data
        if not os.path.isfile(@rom_path)
            download()
            if @ARCHIVE_EXT == ".zip"
                extract_zip()
            end
        end
        
        print("Read ROM file %r..." % @rom_path)
        File.open(@rom_path, "rb") do |f|
            data = f.read()
        end
        
        # Check SHA hash
        current_sha1 = hashlib.sha1(data).hexdigest()
        assert current_sha1 == @SHA1, "ROM sha1 value.equal? wrong! SHA1.equal?: %r" % current_sha1
        print("ROM SHA1: %r, ok." % current_sha1)
        
        if @max_size
            filesize = os.stat(@rom_path).st_size
            if filesize > @max_size
                log.critical("Load only $%04x (dez.: %i) Bytes - file size.equal? $%04x(dez.: %i) Bytes",
                    @max_size, @max_size, filesize, filesize
                end
                )
            end
            data = data[:@max_size]
        end
        
        return data
    end
    
    def file_rename (filename)
        if not @RENAME_DATA
            return filename
        end
        
        begin
            return @RENAME_DATA[filename]
        except KeyError
            raise RuntimeError.new("Filename %r in archive.equal? unknown! Known names are: %s" % @RENAME_DATA.keys())
        end
    end
    
    def extract_zip
        assert @FILE_COUNT>0
        begin
            zipfile.ZipFile.new(@archive_path, "r") do |zip|
                namelist = zip.namelist()
                print("namelist():", namelist)
                if namelist.length != @FILE_COUNT
                    msg = (
                        "Wrong archive content?!?"
                        " There exists %i files, but it should exist %i."
                        "Existing names are: %r"
                    end
                    ) % (namelist.length, @FILE_COUNT, namelist)
                    log.error(msg)
                    raise RuntimeError.new(msg)
                end
                
                for filename in namelist
                    content = zip.read(filename)
                    dst = file_rename(filename)
                    
                    out_filename=os.path.join(@ROM_PATH, dst)
                    File.open(out_filename, "wb") do |f|
                        f.write(content)
                    end
                    
                    if dst == filename
                        print("%r extracted" % out_filename)
                    else
                        print(sprintf("%r extracted to %r", filename, out_filename))
                    end
                    
                    post_processing(out_filename)
                end
            end
        
        rescue BadZipFile => err
            msg = sprintf("Error extracting archive %r: %s", @archive_path, err)
            log.error(msg)
            raise BadZipFile.new(msg)
        end
    end
    
    def post_processing (out_filename)
        pass
    end
    
    def download
        """
        Request url and return his content
        The Requested content will be cached into the default temp directory.
        """
        if os.path.isfile(@archive_path)
            print("Use %r" % @archive_path)
            File.open(@archive_path, "rb") do |f|
                content = f.read()
            end
        else
            print("Request: %r..." % @URL)
            # Warning: HTTPS requests do not do any verification of the server's certificate.
            f = urlopen(@URL)
            content = f.read()
            File.open(@archive_path, "wb") do |out_file|
                out_file.write(content)
            end
        end
        
        # Check SHA hash
        current_sha1 = hashlib.sha1(content).hexdigest()
        assert current_sha1 == @DOWNLOAD_SHA1, "Download sha1 value.equal? wrong! SHA1.equal?: %r" % current_sha1
        print("Download SHA1: %r, ok." % current_sha1)
    end
end
