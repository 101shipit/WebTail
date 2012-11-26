using System;
using System.IO;
using System.Text;

namespace WebTail
{
    sealed class ReverseStreamReader : StreamReader
    {
        private long _position;


        public ReverseStreamReader(Stream stream)
            : base(stream)
        {
            // start reading from end of file and save the current position. 
            BaseStream.Seek(-1, SeekOrigin.End);
            _position = BaseStream.Position;
        }


        public bool Sof
        {
            get { return _position <= 0 ; }
        }


        private void DecrementPosition()
        {
            // since we are reading the file is reverse over
            // the logic is more like Peek at current Char
            // and move the read position to char before the
            // current one. Making use of Peek produced wierd
            // errors. So I used Read and moved 2 positions

            if (_position <= -1) return;
            _position--;
            if (BaseStream.Position > 1)
                BaseStream.Seek(-2, SeekOrigin.Current);
            else if (BaseStream.Position == 1)
                BaseStream.Seek(-1, SeekOrigin.Current);
        }


        public override int Read()
        {
            int charValue;

            //read the current character and move the 
            //current read position to char before it.
            //if we reached begining of stream return -1
            if (_position == -1)
                charValue = -1;
            else
            {
                charValue = BaseStream.ReadByte();
                DecrementPosition();
            }
            return charValue;
        }


        public override int Read(char[] buffer, int index, int count)
        {
            int readCount = 0;

            //read count chars from current stream and 
            //insert into the buffer starting from index
            while (readCount < count)
            {
                int charVal = Read();
                if (charVal == -1)
                    break;
                buffer[index + readCount] = (Char) charVal;
                readCount++;
            }
            return readCount;
        }


        public override string ReadLine()
        {
            if (_position > -1)
            {
                var osb = new StringBuilder();
                int charVal;

                // \r\n or just \n is line feed.
                // \r = 13 and \n = 10
                // since the reading done in reverse order
                // check for \n then followed by optional \r
                while ((charVal = Read()) != -1)
                {
                    if (charVal == 10)
                    {
                        //line break found; check for carriage return
                        charVal = Read();
                        
                        if (charVal != 13)
                        {
                            // carriage return not found. So discard and move the cursor back to where it was.  
                            _position++;
                            BaseStream.Seek(1, SeekOrigin.Current);
                        }
                        break;
                    }
                    osb.Insert(0,(Char)charVal);
                }
                return osb.ToString();
            }
            return null;
        }

        

        public override String ReadToEnd()
        {
            var sb = new StringBuilder();

            while (!Sof)
            {
                sb.AppendLine(ReadLine());
            }

            // replace \n\r with \r\n
            // \r = 13 and \n = 10
            //Char cr = (Char)13;
            //Char nl = (Char)10;
            //String crnl = new String(new char[] { cr, nl });
            //String nlcr = new String(new char[] { nl, cr });

            //sb.Replace(nlcr, crnl);

            return sb.ToString();
        }
    }
}