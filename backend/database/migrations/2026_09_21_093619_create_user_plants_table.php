<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{

    public function up(): void
    {
        Schema::create('user_plants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('location_id')->constrained('locations')->cascadeOnDelete();
            $table->string('plant_name');
            $table->enum('planting_medium', ['home_yard', 'open_land', 'pot']);
            $table->enum('soil_type', ['fertile', 'clay', 'sandy', 'chalky', 'volcanic', 'peat', 'artificial_media']);
            $table->enum('current_phase', ['seedling', 'early_vegetative', 'late_vegetative', 'generative'])->default('seedling');
            $table->date('phase_start_date');
            $table->date('planting_date');
            $table->json('watering_config');
            $table->json('fertilizing_config');
            $table->date('last_watered_date')->nullable();
            $table->date('last_fertilized_date')->nullable();
            $table->date('adjusted_due_date')->nullable();
            $table->unsignedSmallInteger('delay_streak_days')->default(0);
            $table->enum('status', ['active', 'archived', 'failed'])->default('active');
            $table->timestamps();
            $table->index(['status', 'location_id']);
            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_plants');
    }
};
