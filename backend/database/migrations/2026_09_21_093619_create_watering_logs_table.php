<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{

    public function up(): void
    {
        Schema::create('watering_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_plant_id')->constrained('user_plants')->cascadeOnDelete();
            $table->enum('phase_at_time', ['seedling', 'early_vegetative', 'late_vegetative', 'generative']);
            $table->date('scheduled_date');
            $table->date('actual_date')->nullable();
            $table->enum('status', ['watered', 'skip_rain', 'partial_rain', 'delayed_rain_expected', 'need_water', 'missed']);
            $table->unsignedSmallInteger('delay_streak_at_time')->default(0);
            $table->enum('rain_confirmed', ['yes', 'no', 'not_answered'])->nullable();
            $table->enum('user_moisture_feedback', ['moist', 'dry', 'not_answered'])->nullable();
            $table->json('weather_snapshot')->nullable();
            $table->timestamps();
            $table->index(['user_plant_id', 'scheduled_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('watering_logs');
    }
};
