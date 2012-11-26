using System;
using System.Text;
using System.IO;

namespace WebTail.Code
{
    public class BackwardReader : IDisposable
    {
        private readonly string _path;
        private readonly FileStream _fs;

        public BackwardReader(string path)
        {
            _path = path;
            _fs = new FileStream(_path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
            _fs.Seek(0, SeekOrigin.End);
        }

        public string Readline()
        {
            var text = new byte[1];
            _fs.Seek(0, SeekOrigin.Current);
            var position = _fs.Position;

            //do we have trailing \r\n?
            if (_fs.Length > 1)
            {
                var vagnretur = new byte[2];
                _fs.Seek(-2, SeekOrigin.Current);
                _fs.Read(vagnretur, 0, 2);
                if (Encoding.ASCII.GetString(vagnretur).Equals("\r\n"))
                {
                    //move it back
                    _fs.Seek(-2, SeekOrigin.Current);
                    position = _fs.Position;
                }
            }

            while (_fs.Position > 0)
            {
                text.Initialize();
                //read one char
                _fs.Read(text, 0, 1);
                var asciiText = Encoding.ASCII.GetString(text);
                //moveback to the charachter before
                _fs.Seek(-2, SeekOrigin.Current);
                if (!asciiText.Equals("\n")) continue;
                _fs.Read(text, 0, 1);
                asciiText = Encoding.ASCII.GetString(text);
                if (!asciiText.Equals("\r")) continue;
                _fs.Seek(1, SeekOrigin.Current);
                break;
            }
            var count = int.Parse(Convert.ToString(position - _fs.Position));
            var line = new byte[count];
            _fs.Read(line, 0, count);
            _fs.Seek(-count, SeekOrigin.Current);
            return Encoding.ASCII.GetString(line);
        }

        public bool SOF
        {
            get { return _fs.Position == 0; }

        }

        public void Close()
        {
            _fs.Close();
        }


        #region IDisposable Members

        public void Dispose()
        {
            _fs.Close();
        }

        #endregion
    }
}