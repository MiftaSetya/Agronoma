<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{

    public function up(): void
    {
        Schema::create('weather_cache', function (Blueprint $table) {
            $table->id();
            $table->string('city');
            $table->string('province')->nullable();
            $table->date('date');
            $table->enum('condition', ['sunny', 'partly_cloudy', 'cloudy', 'light_rain', 'moderate_rain', 'heavy_rain']);
            $table->decimal('rainfall_mm', 6, 2)->default(0);
            $table->unsignedTinyInteger('rain_probability_percent')->default(0);
            $table->decimal('temp_min', 4, 1)->nullable();
            $table->decimal('temp_max', 4, 1)->nullable();
            $table->timestamp('fetched_at')->useCurrent();
            $table->unique(['city', 'province', 'date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('weather_cache');
    }
};
