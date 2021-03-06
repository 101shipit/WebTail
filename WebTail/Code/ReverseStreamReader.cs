﻿using System;
using System.IO;
using System.Text;

namespace WebTail.Code
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
            if (_position <= -1) 
                return;
            _position--;
            if (BaseStream.Position > 1)
                BaseStream.Seek(-2, SeekOrigin.Current);
            else if (BaseStream.Position == 1)
                BaseStream.Seek(-1, SeekOrigin.Current);
        }


        public override int Read()
        {
            int charValue;

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
            var readCount = 0;

            while (readCount < count)
            {
                var charVal = Read();
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
                var stringBuilder = new StringBuilder();
                int charVal;

                // \r\n or just \n is line feed. \r = 13 and \n = 10
                // since the reading done in reverse order check for \n then followed by optional \r
                while ((charVal = Read()) != -1)
                {
                    if (charVal == 10)
                    {
                        //line break found, check for carriage return
                        charVal = Read();
                        if (charVal != 13)
                        {
                            // carriage return not found. So discard and move the cursor back to where it was.  
                            _position++;
                            BaseStream.Seek(1, SeekOrigin.Current);
                        }
                        break;
                    }
                    stringBuilder.Insert(0,(Char)charVal);
                }
                return stringBuilder.ToString();
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

            return sb.ToString();
        }
    }
}