import { Body, HttpException, HttpStatus, Injectable, Post } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User } from 'src/schemas/User.schema';
import { CreateUserDto } from './dto/CreateUser.dto';
import { UpdateUserDto } from './dto/UpdateUser.dto';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';



@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private userModel: Model<User>,
    private readonly jwtService: JwtService
  ) {}



  async register(createUserDto: CreateUserDto) {
    console.log("🔹 Raw Password Before Hashing:", createUserDto.password);
  
    // ✅ Ensure password is hashed correctly before saving
    const hashedPassword = await bcrypt.hash(createUserDto.password, 10);
  
    console.log("✅ Hashed Password:", hashedPassword);
  
    const newUser = new this.userModel({
      email: createUserDto.email,
      username: createUserDto.username,
      password: hashedPassword, // ✅ Store the hashed password
    });
  
    return await newUser.save();
  }
  
  

  
  

  async login(email: string, password: string) {
    console.log("🔎 Checking email:", email);

    const user = await this.userModel.findOne({ email });

    if (!user) {
      console.log("❌ No user found with this email!");
      throw new HttpException({ message: 'Invalid email or password' }, HttpStatus.UNAUTHORIZED);
    }

    console.log("✅ User found:", user);

    // 🔹 Print the stored hashed password
    console.log("🔑 Stored Hashed Password:", user.password);
    console.log("🔑 Entered Password:", password);

    // 🔹 Compare the entered password with the hashed password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    console.log("🔍 Password Match Result:", isPasswordValid);

    if (!isPasswordValid) {
      console.log("❌ Password does not match!");
      throw new HttpException({ message: 'Invalid email or password' }, HttpStatus.UNAUTHORIZED);
    }

    // 🔹 Generate JWT token
    const payload = { email: user.email, sub: user._id };
    const token = this.jwtService.sign(payload);

    console.log("✅ Login successful! Token:", token);

    // ✅ Include `user` object in the response
    return {
      success: true,
      message: 'Login successful',
      token,
      user: {
        _id: user._id,
        email: user.email,
        username: user.username
      }
    };
}

  


  getsUsers() {
    return this.userModel.find();
  }

  getUserById(id: string) {
    return this.userModel.findById(id);
  }

  async updateUser(id: string, updateUserDto: UpdateUserDto): Promise<User | null> {
    const updatedUser = await this.userModel.findByIdAndUpdate(id, updateUserDto, { new: true });
    return updatedUser; // Return the updated document or null if not found
  }

  deleteUser(id: string) {
    return this.userModel.findByIdAndDelete(id);
  }

// Add the findByEmail method
async findByEmail(email: string): Promise<User | null> {
  return this.userModel.findOne({ email }).exec(); // Find user by email
}
}