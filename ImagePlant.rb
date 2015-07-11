#!/usr/bin/ruby

require 'fileutils'

DST_DIR    = "./dst"
TMP_DIR     = "./tmp"

#----------------------------------------------
# 命名規則は違えどディレクトリ内では
# ソートされているファイルをまとめるスクリプト
#----------------------------------------------

class ImagePlant
    
    def initialize()
        FileUtils.rm_rf(TMP_DIR)
        FileUtils.mkdir_p(TMP_DIR)
        
        FileUtils.rm_rf(DST_DIR)
        FileUtils.mkdir_p(DST_DIR)

        # 扱うファイル総数をカウントする
        srcInfo = Hash.new()
        srcInfo['total'] = 0
        srcInfo['dir'] = Hash.new()

        if ARGV[0] then
            srcDir = ARGV[0]
        else
            srcDir = './src'
        end

        if !Dir.exist?(srcDir) then
            puts 'Error: non exist dir'
            puts 'make \'src\' directory first or specify valid directory'
            exit()
        end

        Dir.foreach(srcDir){|dir|
            if dir[0,1] == '.' then
                next
            end
            # puts dir
            count = 0
            dirPath = srcDir + '/' + dir
            for f in Dir.open(dirPath).sort do
                # puts f
                if f[0,1] != '.' then
                    count += 1
                end
            end
            srcInfo['dir'][dirPath] = count
            srcInfo['total'] = srcInfo['total'] + count
        }
        @srcInfo = srcInfo
        #p @srcInfo
    end

    def normalize(dir)
        # ディレクトリの中をファイル名でソートして
        # リネーム済みのディレクトリを作成する
        index = 0
        tmpPath = TMP_DIR + '/' + dir
        FileUtils.mkdir_p(tmpPath)
        stride = (@srcInfo['total'] * 2)/ (@srcInfo['dir'][dir] + 1)

        for f in Dir.open(dir).sort do
            if f[0,1] == '.' then
                next
            end
            FileUtils.copy(dir + '/' + f, tmpPath + '/' + (stride * index).to_s + '.jpg')
            index = index + 1
        end
    end

    # ファイル名の衝突を残したままディレクトリを統合する
    def phase1Union()
        phase1Dir = TMP_DIR + '/phase'
        FileUtils.mkdir_p(phase1Dir)

        Dir.foreach(TMP_DIR + '/src'){|dir|
            if dir[0, 1] == '.' then
                next
            end
            for f in Dir.open(TMP_DIR + '/src/' + dir).sort do
                if f[0, 1] == '.' then
                    next
                end
                    
                src = TMP_DIR + '/src/' + dir + '/' + f
                dst = phase1Dir + '/'

                if(File.exist?(phase1Dir + '/' + f)) then
                    ext = File.extname(f)
                    base = File.basename(f, ext)
                    utime = Time.now.to_i.to_s + Time.now.usec.to_i.to_s
                    FileUtils.copy(src, dst + base + utime + ext)
                else
                    FileUtils.copy(src, dst + f)
                end
            end
        }
    end

    # phaseディレクトリの衝突を解消する
    def phase2Union()
        count = 0
        for f in Dir.open(TMP_DIR + '/phase').sort do
            if f[0, 1] == '.' then
                next
            end
            # puts f
            count = count + 1
            src = TMP_DIR + '/phase/' + f
            # 一応真面目に計算する
            ext = File.extname(TMP_DIR + '/phase/' + f)
            dst = DST_DIR + '/' + count.to_s + ext
            FileUtils.copy(src, dst)
        end
    end

    def cleanup()
        FileUtils.rm_r(TMP_DIR)
    end

    def execute()
      # ディレクトリごとに準正規化する
      @srcInfo['dir'].each{|dir, count|
        self.normalize(dir)
      }

      # 準正規化されたファイルを結合する
      self.phase1Union()    # 名前が衝突は残して結合
      self.phase2Union()    # 名前の衝突を解決する
      self.cleanup()
    end
end

plant = ImagePlant.new()
plant.execute()


