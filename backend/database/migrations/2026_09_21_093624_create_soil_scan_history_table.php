<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{

    public function up(): void
    {
        Schema::create('soil_scan_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('image_url');
            $table->enum('detected_soil_type', ['fertile', 'clay', 'sandy', 'chalky', 'volcanic', 'peat', 'artificial_media']);
            $table->decimal('ai_confidence', 5, 2)->nullable();
            $table->timestamp('scanned_at')->useCurrent();
            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('soil_scan_history');
    }
};
